package Catalyst::View::TT::ForceUTF8;

use strict;

use base 'Catalyst::View::TT';

our $VERSION = '0.13';

use Template::Provider::Encoding 0.09;
use Template::Stash::ForceUTF8;
use Path::Class;

my @PROVIDER_CONFIG_KEYS = qw/
  INCLUDE_PATH
  DEFAULT_ENCODING
  COMPILE_DIR
  COMPILE_EXT
  EVAL_PERL
  PARSER
  PRE_CHOMP
  POST_CHOMP
/;

# XXX: this is but a copy from View::TT.
#      But this subroutine isn't class or instance method,
#      so this module couldn't inherit from View::TT
sub _coerce_paths {
  my ($paths, $dlim) = @_;
  return () if (!$paths);
  return @{$paths} if (ref $paths eq 'ARRAY');
  unless (defined $dlim) {
    $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':';
  }
  return split(/$dlim/, $paths);
}

sub new {
  my ( $class, $c, $arguments ) = @_;
  my $config = {%{$class->config}, %{$arguments}};

  # XXX: copied from View::TT
  if (!(ref $config->{INCLUDE_PATH} eq 'ARRAY')) {
    my $delim = $config->{DELIMITER};
    my @include_path
      = _coerce_paths($config->{INCLUDE_PATH}, $delim);
    if ( !@include_path ) {
      my $root = $c->config->{root};
      my $base = Path::Class::dir($root, 'base');
      @include_path = ("$root", "$base");
    }
    $config->{INCLUDE_PATH} = \@include_path;
  }

  my %args = map  { ($_, $config->{$_})  }
             grep { exists $config->{$_} }
             @PROVIDER_CONFIG_KEYS;

  $class->config->{PROVIDERS} = [ {
    name => 'Encoding',
    args => \%args,
    copy_config => [qw(INCLUDE_PATH)],
  }, ];
  $class->config->{STASH} = Template::Stash::ForceUTF8->new;
  $class->config->{STRICT_CONTENT_TYPE} ||= 0;
  $class->SUPER::new($c, $arguments);
}

sub process {
  my ($self, $c) = @_;
  unless ($c->res->content_type) {
    if ($self->config->{STRICT_CONTENT_TYPE}) {
      my $agent = $c->req->user_agent || '';
      $c->res->content_type(
        $agent =~ /MSIE/
          ? 'text/html; charset=utf-8'
          : 'application/xhtml+xml; charset=utf-8'
      );
    }
  }
  $self->SUPER::process($c);
}

=head1 NAME

Catalyst::View::TT::ForceUTF8 - (DEPRECATED) Template View Class with utf8 encoding

=head1 SYNOPSIS

  package MyApp::View::TT;
  use base 'Catalyst::View::TT::ForceUTF8';

=head1 DESCRIPITON

Template View Class with utf8 encoding.

This allows you to prevent publishing garbled result.

Now this module is deprecated.
http://dev.catalystframework.org/wiki/gettingstarted/tutorialsandhowtos/using_unicode

=head1 CONFIG

  __PACKAGE__->config(
    INCLUDE_PATH        => [..],
    TIMER               => 0,
    ... # and other View::TT's configuration.
    STRICT_CONTENT_TYPE => 1,
    DEFAULT_ENCODING    => 'utf-8',
  );


=over 4

=item DEFAULT_ENCODING

'utf-8' is set by default. See more detail L<Template::Provider::Encoding>.

=item CONTENT TYPE

When you set *STRICT_CONTENT_TYPE* configuration,
It automatically set content-type 'application/xhtml+xml; charset=utf-8'
for browsers except MSIE.

=back

=head1 SEE ALSO

L<Catalyst::View::TT>, L<Template::Provider::Encoding>

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LISENCE

The library if free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
