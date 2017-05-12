package Catalyst::Plugin::AtomPP;
use strict;
use Catalyst::Utils;
use XML::Atom;
use XML::Atom::Entry;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::AtomPP - Dispatch AtomPP methods with Catalyst.

=head1 SYNOPSIS

  use Catalyst qw/AtomPP/;

  sub entry : Local {
      my ($self, $c) = @_;
      $c->atom;             # dispatch AtomPP methods.
  }

  sub create_entry : Remote {
      my ($self, $c, $entry) = @_;
      # $entry is XML::Atom Object from Request content

      ...
  }

  sub retrieve_entry : Remote {
      my ($self, $c) = @_;

      ...
  }

  sub update_entry : Remote {
      ...
  }

  sub delete_entry : Remote {
      ...
  }

=head1 DESCRIPTION

This plugin allows you to dispatch AtomPP methods with Catalyst.

Require other authentication plugin, if needed.
(Authentication::CDBI::Basic, WSSE, or so)

=head1 METHODS

=over 4

=item atom

=cut

sub atom {
    my $c = shift;

    my $class = caller(0);
    (my $method = $c->req->action) =~ s!.*/!!;

    my %prefixes = (
        POST   => 'create_',
        GET    => 'retrieve_',
        PUT    => 'update_',
        DELETE => 'delete_',
    );

    if (my $prefix = $prefixes{$c->req->method}) {
        $method = $prefix.$method;
    } else {
        $c->log->debug(qq!Unsupported Method "@{[$c->req->method]}" called!);
        $c->res->status(501);
        return;
    }

    $c->log->debug("Method: $method");

    if (my $code = $class->can($method)) {
        my ($pp, $res);

        for my $attr (@{Catalyst::Utils::attrs($code)}) {
            $pp++ if $attr eq 'Remote';
        }

        if ($pp) {
            my $content = $c->req->body;
            my $entry;
            $entry = XML::Atom::Entry->new(\$content) if $content;
            if ($c->req->body and !$entry) {
                $c->log->debug("Request body is not well-formed.");
                $c->res->status(415);
            } else {
                $class = $c->components->{$class} || $class;
                my @args = @{$c->req->args};
                $c->req->args([$entry]) if $entry;
                $c->actions->{reverse}->{$code} ||= "$class->$method";
                $c->state($c->execute($class, $code));

                $c->res->content_type('application/xml; charset=utf-8');
                $c->res->body($c->state);
                $c->req->args(\@args);
            }
        }

        else {
            $c->log->debug(qq!Method "$method" has no Atom attribute!);
            $c->res->status(501);
        }
    }
}

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::XMLRPC>.

=head1 AUTHOR

Daisuke Murase, E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

