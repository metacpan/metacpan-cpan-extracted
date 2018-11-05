package Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser ;
$Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser::VERSION = '0.006';
use strict;
use warnings;
use Markdent::Parser;
use Moose;
extends 'Markdent::Handler::HTMLStream::Fragment';

has 'event_stash' => (is => 'rw', isa => 'ArrayRef', default => sub { [] }, writer => '_set_stash');
has 'event_chain' => (traits => [ 'Array' ], is => 'ro', isa => 'ArrayRef',
                      builder => '_get_event_chain', lazy => 1,
                      writer => '_set_event_chain',
                      handles => { shift_chain => 'shift', chain_empty => 'is_empty' } );
has 'add_class'        => (is => 'rw', isa => 'Bool', default => 0, writer => '_set_add_class');
has 'linkable_headers' => (is => 'ro', isa => 'Bool', default => 0);
has 'header_class'     => (is => 'ro', isa => 'Str', default => '');
has 'dialect'          => (is => 'ro', isa => 'Str', default => 'GitHub');
has 'header_count'     => (is => 'rw', isa => 'Int', default => 0, writer => '_set_header_count');

sub _inc_header_count {
  my $s = shift;
  $s->_set_header_count($s->header_count + 1);
}

# shift the next event off the event_chain
sub _get_next_event {
  my $s = shift;
  $s->shift_chain;
}

# reset the event chain back to original
sub _reset_event_chain {
  my $s = shift;
  $s->_set_event_chain($s->_get_event_chain);
}

# look for events in the following order
sub _get_event_chain {
  return [ qw ( start_paragraph start_code text end_code text ) ];
}

sub handle_event {
    my ($self, $event)  = @_;
    my $meth = $event->event_name();
    my $next = $self->_get_next_event;

    if ($self->chain_empty) {
      if ($meth eq $next && $event->text =~ /^\s+$/) {
        $self->_set_add_class(1);
      }
    } elsif ($meth eq $next) {
      push @{$self->event_stash}, $event;
      return;
    }

    $self->_unravel_stash;
    $self->$meth( $event->kv_pairs_for_attributes() );
}

sub _unravel_stash {
  my $s = shift;
  my @events = @{$s->event_stash};
  foreach my $event (@events) {
    my $meth = $event->event_name();
    $s->$meth( $event->kv_pairs_for_attributes() );
  }
  $s->_reset_event_chain;
  $s->_set_stash( [ ] );
}

sub start_code {
  my $s = shift;
  if ($s->add_class) {
    $s->_stream_start_tag( 'code', { class => 'single-line' });
  } else {
    $s->_stream_start_tag( 'code' );
  }
  $s->_set_add_class(0);
}

sub parse {
	my $s = shift;
  my $markdown = shift;

	my $parser = Markdent::Parser->new( dialects => $s->dialect, handler => $s );
	$parser->parse( markdown => $$markdown );
}

sub start_header {
  my $s = shift;
  my $level = $_[1];

  my %attributes = ();
  if ($s->header_class) {
    $attributes{class} = $s->header_class;
  }
  if ($s->linkable_headers) {
    $attributes{id} = "header_${level}_" . $s->header_count;
    $s->_inc_header_count;
  }

  $s->_stream_start_tag( 'h' . $level, \%attributes );
}

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Supplies an object for parsing markdown files for the L<Dancer2::Plugin::MarkdownFilesToHTML>
plugin. It extends the C<Markdent::Handler::HTMLStream::Fragment> class and overrides
approrpiate methods to inject custom HTML into the output as needed. Specifically:

=over 2

=item * adds the class C<single-line> to a line of code appearing on a single
line by itself

=item * optionally adds classes and a unique id to header tag HTML elements

=back

=head1 CONFIGURATION

None.

=head1 REQUIRES

=over 4

=item * L<Markdent::Parser|Markdent::Parser>

=item * L<Moose|Moose>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/Dancer2-Plugin-MarkdownFilesToHTML/issues>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

L<Markdent>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
