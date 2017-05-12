package Combust::Spontaneously;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use base 'HTTP::Server::Simple::Er';

# "pretend" we already loaded some stuff we're not going to need
$INC{do{my $x = $_; $x =~ s#::#/#g; $x.".pm"}} = '/dev/null' for(
 'Apache2::SubRequest',
 'DBI',
);

$INC{'Cache/Memcached.pm'} = 1;
*Cache::Memcached::new = sub {shift};

use Class::Accessor::Classy;
ro 'site';
ro 'control';
no  Class::Accessor::Classy;

=head1 NAME

Combust::Spontaneously - combust standalone server class

=head1 SYNOPSIS

See `perldoc combustier` for recommended usage.

=cut

=begin pretend_coverage

=head2 new

=end pretend_coverage

=cut

sub new {
  my $self = shift->SUPER::new(@_);

  $self->fakeup_request_class;
  require Combust::Control::Basic;

  my $control = $self->{control} = Combust::Control::Basic->new;
  ($control->{site} = $self->site) =~ s#/$##;
  my $path = $control->get_include_path;
  # warn join(', ', @$path);
  $control->tt->set_include_path([$self->site, 'shared', @$path]);
  return($self);
}

my %types = (
  map({$_ => "image/$_"} qw(png jpg)),
  ico => 'image/x-icon',
  map({$_ => "application/"} qw(pdf)),
  ps  => 'application/postscript',
  map({$_ => "text/$_"} qw(css)),
);

=head2 handler

Called by the superclass to handle requests.

  $server->handler;

=cut

sub handler {
  my $self = shift;

  my $path = $self->path;
  $path =~ s{/$}{/index.html};
  $path =~ s#^/##;

  # support runtime dep analysis
  exit if(Devel::TraceDeps->can('import') and $path eq 'exit');

  local $self->control->request->{path} = '/' . $path;

  if($path !~ m/\.html$/) {
    my %params;
    my ($ext) = $path =~ m/\.([^\.]+)$/;
    if(my $type = $types{$ext}) {
      $params{content_type} = $type;
    }
    my $data = $self->control->tt->provider->expand_filename($path);

    my $file = $data->{path} or warn "no data for $path";

    return $self->output(404, "no $path") unless($file and -e $file);

    my $content = do {
      open(my $fh, '<', $file) or
        warn "cannot open $file" and return $self->output(403, 'fail');
      warn "static: $file\n";
      local $/; <$fh>;
    };

    return $self->output(\%params, $content);
  }

  warn "$path\n";
  my $out = eval {$self->control->evaluate_template($path)};
  if(my $err = $@) {
    return $self->output(404, $err);
  }
  #warn $out;
  $self->output($out);
} ######################################################################


=begin internal

=head2 fakeup_request_class

this useless class is just deferring things until after the construction

=end internal

=cut

sub fakeup_request_class {
  package Combust::Request::Spontaneously;
  $INC{'Combust/Request/Spontaneously.pm'} = __FILE__;

  require Combust::Request;
  our @ISA = ('Combust::Request');

  sub _r {shift}
  sub pnotes {shift->notes(@_)}
  sub dir_config {'.'}
  sub document_root {'.'}

  sub req_param {''}
  sub get_cookie {''}
  sub args { 'thbbt' }
  sub uri  { shift->{path} }

}



=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE



=cut

# vi:ts=2:sw=2:et:sta
1;
