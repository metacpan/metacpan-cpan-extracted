package DBIx::VersionedSubs::Hash;
use strict;
use base 'DBIx::VersionedSubs';
use vars qw($VERSION);
use Carp qw(carp croak);

$VERSION = '0.08';

=head1 NAME

DBIx::VersionedSubs::Hash - store subroutines in a simple hash

=head1 SYNOPSIS

  package My::App;
  use strict;
  use base 'DBIx::VersionedSubs::Hash';

  __PACKAGE__->{code} = {
      say_hello => sub {print "Hello World"},
  };

  package main;
  use strict;

  my $app = My::App->new({code => {},dsn => $dsn );
  while (my $request = Some::Server->get_request) {
      $app->update_code(); # update code from the DB
      $app->handle_request->($request);
  }

=head1 ABSTRACT

This module overrides some methods in L<DBIx::VersionedSubs>
and replaces the normal namespace based code storage
with simple storage in a hash.
This is useful if you want multiple code versions
in a mod_perl environment for example.

=cut

=head2 C<< Package->new({ %ARGS }) >>

Creates a new object and initializes it from the class
default values as inherited from L<DBIx::VersionedSubs>.

If you pass in a hashref to the C<code> key, all subroutines will
be stored in it. You can also use this feature to pass in a package
hash (like C< %My::App:: >), then this module will be almost identical
in usage to L<DBIx::VersionedSubs> itself. The difference
between the two is that subroutine names with characters outside of C<\w>
will not create subroutines in other namespaces with this module.

=cut

sub new {
    my ($package,$args) = @_;
    my $code = delete $args->{ code } || {};
    my $self = bless $args, $package;
    $self->setup( %$args );
    $self->{ code } = $code;
    $self;
};

sub create_sub {
    my ($self,$name,$code) = @_;
    my $package = ref $self;
    my $ref = $self->eval_sub($package,$name,$code);
    if ($ref) {
        if ($name eq 'BEGIN') {
            $ref->($self);
	    return undef
	} else {
	    $self->{code}->{$name} = $ref;
	    $self->code_source->{$name} = $code;
	}
    };
    $ref
};

sub destroy_sub {
    my ($self,$name) = @_;
    delete $self->{code}->{$name};
};

=head2 C<< $app->dispatch( FUNCTION, ARGS ) >>

This is a shorthand method for

    return $self->{code}->{$function}->(@ARGS);

except with error checking

=cut

sub dispatch {
    my $self= shift;
    my $name= shift;
    my $code= $self->{code}->{$name} || sub {croak "Undefined subroutine '$name' called."};
    goto &$code;
};

# Install our accessors
for (qw(code_source code_live code_history code_version verbose dsn)) {
    my $name = $_;
    no strict 'refs';
    *{__PACKAGE__ . "::$name"} = sub {
        @_ > 1 ?  $_[0]->{$name} = $_[1] : $_[0]->{$name}
    };
};

1

__END__

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut

