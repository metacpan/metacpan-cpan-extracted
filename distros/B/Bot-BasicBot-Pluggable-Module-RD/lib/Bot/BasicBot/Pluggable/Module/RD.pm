package Bot::BasicBot::Pluggable::Module::RD;
use strict;

our $VERSION = '0.02';
use base qw(Bot::BasicBot::Pluggable::Module);
use Bot::BasicBot::Pluggable::Module::RD_Basic;
use Parse::RecDescent;
use Parse::RecDescent::Deparse;
use Parse::RecDescent::Topiary;

=head1 NAME

Bot::BasicBot::Pluggable::Module::RD - RecDescent grammar adaptor plugin

=head1 SYNOPSIS

  !load RD

See the synopsis of L<Bot::BasicBot::Pluggable> for how to load this plugin.

=head1 DESCRIPTION

Many bots are concerned with responding to commands issued on IRC. The simple
approach of regular expressions is used by many of the bot plugins. However,
this module offers full syntax parsing via L<Parse::RecDescent>.

Rather than each bot plugin doing its own parsing in an overridden C<said()>
routine, the approach used here is for a single grammar shared between the
bot plugins. This module and namespace is the keeper of the grammar, and
others can extend the grammar by adding rules to it.

The following simple commands are provided:

  say Hello channel
  tell ivorw I'm connected

=head2 Methods C<init>, C<told>, C<help>

See the documentation for L<Bot::BasicBot::Pluggable::Module> and 
L<Bot::BasicBot>.

=head2 extend

This is called by any pluggable modules in order to add rules to the bot's
Parse::RecDescent grammar.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org>.

=head1 AUTHOR

    Ivor Williams
    CPAN ID: IVORW
     
    ivorw@cpan.org
     

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

my $grammar = <<'END';
<autotree>

END

our @namespace;
our $parser;

sub init {
    my $self = shift;

    $parser = Parse::RecDescent->new($grammar)
        or die "Bad grammar";

    $self->Bot::BasicBot::Pluggable::Module::RD_Basic::init();
}

sub extend {
    my ( $self, $newg, $class ) = @_;

    die "RD Parser not initialised - load RD module" unless $parser;
    $parser->Extend($newg);
    if ($class) {
        push @namespace, $class;
    }
}

sub told {
    my ( $self, $mess ) = @_;

    my $body = $mess->{body};

    return unless $mess->{address};

    my $tree = topiary(
        tree        => $parser->command($body),
        namespace   => [ __PACKAGE__, @namespace ],
        ucfirst     => 1,
        consolidate => 1,
    );

    if ($tree) {
        $tree->despatch( $self, $mess );
    }
    else {
        my $bot = $self->bot or die "No bot";
        my $nick = $bot->nick;
        return ( $mess->{raw_body} =~ /^$nick[:,]/ )
            ? 0
            : "Sorry, I don't understand $body";
    }
}

sub help {
    my $self = shift;

    $self->Bot::BasicBot::Pluggable::Module::RD_Basic::help;
}

package Bot::BasicBot::Pluggable::Module::RD::Command;
use strict;

use base qw(Parse::RecDescent::Topiary::Base);

1;

sub despatch {
    my $self = shift;

    if ( exists $self->{__STRING1__} ) {
        my $verb  = $self->{__STRING1__};
        my $class = Parse::RecDescent::Topiary::delegation_class( 'Command',
            \@namespace, $verb );
        my $meth = $class . '::' . $verb;
        return $self->$meth(@_);
    }
}
