package DB::Pluggable::Plugin::TypeAhead;
use strict;
use warnings;
use 5.010;
use Brickyard::Accessor rw => [qw(type ifenv)];
use Role::Basic;
with qw(DB::Pluggable::Role::AfterInit);
our $VERSION = '1.112001';

sub afterinit {
    my $self = shift;
    my $type = $self->type;
    die "TypeAhead: need 'type' config key\n" unless defined $type;
    die "TypeAhead: 'type' must be an array reference of things to type\n"
      unless ref $type eq 'ARRAY';
    if (my $env_key = $self->ifenv) {
        return unless $ENV{$env_key};
    }
    no warnings 'once';
    push @DB::typeahead, @$type;
}
1;

=pod

=for stopwords typeahead afterinit

=for test_synopsis 1;
__END__

=head1 NAME

DB::Pluggable::Plugin::TypeAhead - Debugger plugin to add type-ahead

=head1 SYNOPSIS

    $ cat ~/.perldb
    use DB::Pluggable;
    DB::Pluggable->run_with_config(\<<EOINI)
    [TypeAhead]
    type = {l
    type = c
    ifenv = DBTYPEAHEAD
    EOINI

=head1 DESCRIPTION

If you use the debugger a lot, you might find that you enter the same commands
after starting the debugger. For example, suppose that you usually want to
list the next window of lines before the debugger prompt - so you would enter
C<{l> - and that you usually have a breakpoint when running the debugger - so
you would enter C<c>. So you could use a plugin configuration as shown in
the synopsis.

If you want to control whether this typeahead is applied, you can use the
optional C<ifenv> configuration key. If specified, its value is taken to be
the name of an environment variable. When the plugin runs, the typeahead will
only be applied if that environment variable has a true value.

So to continue the example from the synopsis, if you wanted to enable the
typeahead, you would run your program like this:

    DBTYPEAHEAD=1 perl -d ...

The inspiration for this plugin came from Ovid's blog post at
L<http://blogs.perl.org/users/ovid/2010/02/easier-test-debugging.html>.

=head1 METHODS

=head2 afterinit

Pushes the commands to the debugger's typeahead.
