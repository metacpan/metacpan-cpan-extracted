package App::Adenosine::Plugin::Rainbow;
$App::Adenosine::Plugin::Rainbow::VERSION = '2.001008';
use Moo;

with 'App::Adenosine::Role::FiltersStdErr';
use Module::Runtime 'require_module';
use Try::Tiny;

try {
   require_module('Term::ExtendedColor')
} catch {
   die <<"ERR"
Term::ExtendedColor must be installed to use ::Rainbow

original error: $_
ERR
};

our %old_colormap = (
   red => 1,
   green => 2,
   yellow => 3,
   blue => 4,
   purple => 5,
   cyan => 6,
   white => 7,
   gray => 8,
   bright_red => 9,
   bright_green => 10,
   bright_yellow => 11,
   bright_blue => 12,
   magenta => 13,
   bright_cyan => 14,
   bright_white => 15,
);

sub colorize {
   my ($self, $arg, $str) = @_;

   $arg = { fg => $arg } unless ref $arg;

   for (qw(fg bg)) {
      $arg->{$_} = $old_colormap{$arg->{$_}}
         if $arg->{$_} && exists $old_colormap{$arg->{$_}}
   }

   $str = Term::ExtendedColor::fg($arg->{fg}, $str ) if $arg->{fg};
   $str = Term::ExtendedColor::bg($arg->{bg}, $str ) if $arg->{bg};
   $str = Term::ExtendedColor::bold($str           ) if $arg->{bold};
   $str = Term::ExtendedColor::italic($str         ) if $arg->{italic};
   $str = Term::ExtendedColor::underline($str      ) if $arg->{underline};

   return $str;
}

has response_header_colon_color => (
   is => 'ro',
   default => sub { 'blue' },
);

has response_header_name_color => (
   is => 'ro',
   default => sub { 'cyan' },
);

has response_header_value_color => (
   is => 'ro',
   default => sub { 'bright_cyan' },
);

has request_header_colon_color => (
   is => 'ro',
   default => sub { 'red' },
);

has request_header_name_color => (
   is => 'ro',
   default => sub { 'purple' },
);

has request_header_value_color => (
   is => 'ro',
   default => sub { 'magenta' },
);

has info_star_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has response_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_method_color => (
   is => 'ro',
   default => sub { 'red' },
);

has request_uri_color => (
   is => 'ro',
   default => sub { {} },
);

has request_protocol_color => (
   is => 'ro',
   default => sub { {} },
);

has request_protocol_version_color => (
   is => 'ro',
   default => sub { 'bright_white' },
);

has response_protocol_color => (
   is => 'ro',
   default => sub { {} },
);

has response_protocol_version_color => (
   is => 'ro',
   default => sub { 'bright_white' },
);

has response_status_code_color => (
   is => 'ro',
   default => sub { 'red' },
);

has response_status_text_color => (
   is => 'ro',
   default => sub { {} },
);

has response_ellided_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has response_ellided_body_color => (
   is => 'ro',
   default => sub { 'blue' },
);

has request_ellided_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_ellided_body_color => (
   is => 'ro',
   default => sub { 'blue' },
);
our $timestamp_re = qr/^(.*?)(\d\d):(\d\d):(\d\d)\.(\d{6})(.*)$/;
# this is probably not right...
our $header_re = qr/^(.+?):\s*(.+)$/;
our $methods_re = qr/HEAD|PUT|POST|GET|DELETE|OPTIONS|TRACE/;
our $request_re = qr<^($methods_re) (.*) (HTTP)/(1\.[01])$>;
our $response_re = qr<^(HTTP)/(1\.[01]) (\d{3}) (.*)$>;

sub filter_request_ellided_body {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->request_ellided_bracket_color, '} ') .
      $self->colorize($self->request_ellided_body_color, $post)
}
sub filter_response_ellided_body {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->response_ellided_bracket_color, '{ ') .
      $self->colorize($self->response_ellided_body_color, $post)
}
sub filter_response_init {
   my ($self, $proto, $ver, $code, $status, $colors) = @_;

   return $self->colorize($colors->{protocol}, $proto) . '/' .
          $self->colorize($colors->{protocol_version}, $ver) . ' ' .
          $self->colorize($colors->{status_code}, $code) . ' ' .
          $self->colorize($colors->{status_text}, $status)
}
sub filter_request_init {
   my ($self, $method, $uri, $proto, $version, $colors) = @_;

   return $self->colorize($colors->{method}, $method) . ' ' .
          $self->colorize($colors->{uri}, $uri) . ' ' .
          $self->colorize($colors->{protocol}, $proto) . '/' .
          $self->colorize($colors->{protocol_version}, $version)
}
sub filter_header {
   my ($self, $name, $value, $colors) = @_;

   return $self->colorize($colors->{name}, $name)  .
          $self->colorize($colors->{colon}, ': ').
          $self->colorize($colors->{value}, $value)

}
sub filter_timestamp {
   my ($self, $pre, $h, $m, $s, $u, $post) = @_;

   return "$pre$h:$m:$s.$u$post";
}
sub filter_info {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->info_star_color, '* ') .
      $post
}
sub filter_response {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   if (my @match = $post =~ $header_re ){
      $post = $self->filter_header(@match, {
         name  => $self->response_header_name_color,
         colon => $self->response_header_colon_color,
         value => $self->response_header_value_color,
      })
   } elsif (my @match2 = $post =~ $response_re) {
      $post = $self->filter_response_init(@match2, {
         protocol         => $self->response_protocol_color,
         protocol_version => $self->response_protocol_version_color,
         status_code      => $self->response_status_code_color,
         status_text      => $self->response_status_text_color,
      })
   }
   return $pre .
      $self->colorize($self->response_bracket_color, '< ') .
      $post
}
sub filter_request {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   if (my @match = ( $post =~ $header_re ) ) {
      $post = $self->filter_header(@match, {
         name  => $self->request_header_name_color,
         colon => $self->request_header_colon_color,
         value => $self->request_header_value_color,
      })
   } elsif (my @match2 = ( $post =~ $request_re ) ) {
      $post = $self->filter_request_init(@match2, {
         method           => $self->request_method_color,
         uri              => $self->request_uri_color,
         protocol         => $self->request_protocol_color,
         protocol_version => $self->request_protocol_version_color,
      })
   }
   return $pre .
      $self->colorize($self->request_bracket_color, '> ') .
      $post
}
sub filter_stderr {
   my ($self, $err) = @_;

   my @out;
   for my $line (map { s/\r$//; $_ } split /\n/, $err) {
      if ($line =~ /^(.*)\* (.*)$/) {
         $line = $self->filter_info($1, $2)
      } elsif ($line =~ /^(.*)< (.*)$/) {
         $line = $self->filter_response($1, $2)
      } elsif ($line =~ /^(.*)> (.*)$/) {
         $line = $self->filter_request($1, $2)
      } elsif ($line =~ /^(.*){ (.*)$/) {
         $line = $self->filter_response_ellided_body($1, $2)
      } elsif ($line =~ /^(.*)} (.*)$/) {
         $line = $self->filter_request_ellided_body($1, $2)
      }
      push @out, $line
   }
   return join "\n", @out, ''
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Adenosine::Plugin::Rainbow

=head1 VERSION

version 2.001008

=head1 DESCRIPTION

Color codes standard error (diagnostics) from curl.  Highly customizable.

=head1 METHODS

=head2 colorize

 $p->colorize('red1', 'Christmas') . ' ' . $p->colorize('green1', 'tree!');

C<colorize> is the method used to highlight all the pieces that come from the
curl output.  It takes two arguments, first a color specification, and next the
string to be colorized.  The complete color specification is defined as:

 {
    fg         => $color,
    bg         => $color,
    bold       => $is_bold,
    italic     => $is_italic,
    underline  => $is_underline,
 }

All of the keys in the hash are optional.  The values for $color can be found
at L<Term::ExtendedColor/Standard color map>.  Additionally I've added a form
of "legacy support" for named 16 color mode. Those colors are actually
arbitrary and most consoles allow you to redefine them, so the names I gave are
just the defaults.  My named colors are:

 red
 green
 yellow
 blue
 purple
 cyan
 white
 gray
 bright_red
 bright_green
 bright_yellow
 bright_blue
 magenta
 bright_cyan
 bright_white

As a shortcut, if you pass a simple string instead of a hashref it wil be
explanded to C<< { fg => $str } >>.

Note that unfortunately support for all the attributes are spotty.
For example on my computer I use tmux 1.6 running within terminator 0.96.
In this situation I can't use any of the non-color attributes.  Outside of
tmux C<underline> works, but the others do not.  Similarly, C<bold> only
seems to work with some colors.  It's pretty frustrating, and experimentation
seems necesary.

=head2 Overriding colors at runtime

To change a color when you run C<adenosine> instantiate it as follows:

 #!/usr/bin/env perl

 use lib 'path/to/adenosine/lib';
 use App::Adenosine;

 use App::Adenosine::Plugin::Rainbow;
 App::Adenosine->new({
    argv => \@ARGV,
    plugins => [
       App::Adenosine::Plugin::Rainbow->new(
          response_header_name_color => 'orange4',
          response_header_value_color => 'orange2',
          response_ellided_body_color => {
             fg => 'blue12',
             bg => 'blue16',
          },
       ),
    ],
 });

=head2 Creating custom themes

To create a custom theme just subclass C<Rainbow> as follows:

 package App::Adennosine::Plugin::Rainbow::Valentine;

 use Moo;
 extends 'App::Adenosine::Plugin::Rainbow';

 has '+response_header_name_color'  => ( default => sub { 'magenta1'  } );
 has '+response_header_value_color' => ( default => sub { 'magenta19' } );
 has '+request_header_name_color'   => ( default => sub { 'magenta7'  } );
 has '+request_header_value_color'  => ( default => sub { 'magenta25' } );

 1;

Then use it the same way you use C<Rainbow>:

 ...
 App::Adenosine->new({ argv => \@ARGV, plugins => ['::Rainbow::Valentine'] })

=head1 COLORABLE SECTIONS

C<Rainbow> splits apart the stderr string from curl and hilights the various
sections respectively.  The values of the sections are what is passed as
the first argument to L</colorize>. The names of the sections are:

=over 2

=item * C<response_header_colon_color>

=item * C<response_header_name_color>

=item * C<response_header_value_color>

=item * C<request_header_colon_color>

=item * C<request_header_name_color>

=item * C<request_header_value_color>

=item * C<info_star_color>

=item * C<response_bracket_color>

=item * C<request_bracket_color>

=item * C<request_method_color>

=item * C<request_uri_color>

=item * C<request_protocol_color>

=item * C<request_protocol_version_color>

=item * C<response_protocol_color>

=item * C<response_protocol_version_color>

=item * C<response_status_code_color>

=item * C<response_status_text_color>

=item * C<response_ellided_bracket_color>

=item * C<response_ellided_body_color>

=item * C<request_ellided_bracket_color>

=item * C<request_ellided_body_color>

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
