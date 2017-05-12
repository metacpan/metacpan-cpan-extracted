use strict;
package Class::DBI::BaseDSN;
use vars qw($VERSION);
$VERSION = '1.22';

sub set_db {
    my $package = shift;
    my ($name, $dsn) = @_;

    my $isa = do { no strict 'refs'; \@{"$package\::ISA"} };
    die "$package is not directly a ".__PACKAGE__
      unless grep { __PACKAGE__ eq $_ } @$isa;

    $dsn =~ m/^(?:dbi:)?([^:]+)/i
      or die "couldn't identify a backend from $dsn";

    my $backend = "Class::DBI::$1";

    unless (eval "require $backend; 1") {
        # Only quash "Can't locate" errors about the class we're pulling in.
	# It may be that we have Class::DBI::$dsn but not something that it 
	# in turn needs (yes, dependencies should fix that, but they don't 
	# always: see rt.cpan.org#3982)

        my $file = $backend;
        $file =~ s{::}{/}g;
        $@ =~ /^Can't locate \Q$file\E\.pm / or die $@;

        # if it simply wasn't there fall back to Class::DBI
        $backend = 'Class::DBI';
        require Class::DBI;
    }

    # okay, get out of the way, and make like we were never here
    for (@$isa) {
        $_ = $backend if $_ eq __PACKAGE__;
    }

    my $method = $package->can('set_db');
    unshift @_, $package;
    goto &$method;
}

1;

__END__

=head1 NAME

Class::DBI::BaseDSN - DSN sensitive base class

=head1 SYNOPSIS

  package My::DBI;
  use base 'Class::DBI::BaseDSN'; # we'll decide later what our real
                                   # parent class will be
  __PACKAGE__->set_db( Main => $ENV{TESTING} ? @test_dsn : @real_dsn );


=head1 DESCRIPTION

Class::DBI::BaseDSN acts as a placeholder for a base class which will
be switched for a specific Class::DBI extension when you specify the
dsn of the database to connect to.

For example in this case, the Class::DBI::BaseDSN will replace itself
with Class::DBI::mysql when the C<set_db> call is executed.

 package Example::DBI;
 use base 'Class::DBI::BaseDSN';
 __PACKAGE__->set_db( Main => 'dbi:mysql:example', 'user', 'pass' );

Since this happens at runtime you could pass the dsn as a variable and
so have it use a completely different extension automatically.  This
is especially useful for testing, or for applications where dsn may be
a configuration option.

If there is no matching extension found, Class::DBI::BaseDSN replaces
itself with Class::DBI.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 THANKS

Thanks go to Michael Schwern for a snippet to fake out caller, and for
hashing out some of the finer points of the approach on the cdbi-talk
list.

=head1 SEE ALSO

L<Class::DBI>

=cut
