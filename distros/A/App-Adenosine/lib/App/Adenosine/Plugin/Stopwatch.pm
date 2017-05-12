package App::Adenosine::Plugin::Stopwatch;
$App::Adenosine::Plugin::Stopwatch::VERSION = '2.001008';
use Moo;

use Time::HiRes qw(gettimeofday tv_interval);

with 'App::Adenosine::Role::WrapsCurlCommand';

sub wrap {
   my ($self, $cmd) = @_;

   return sub {
      my $t0 = [gettimeofday];
      my @ret = $cmd->(@_);
      $ret[1] .= "* Total Time: " . $self->render_duration(tv_interval ( $t0 ));
      return @ret;
   }
}

sub render_duration {
   my ($self, $seconds) = @_;
   if ($seconds < 1 ) {
      return sprintf('%0.f ms', $seconds * 1000);
   } else {
      return sprintf('%1.3f s', $seconds);
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Adenosine::Plugin::Stopwatch

=head1 VERSION

version 2.001008

=head1 DESCRIPTION

Appends handy timer information to curl's stderr, giving the user a simple way
to understand the duration of a requestion.

=head1 METHODS

=head2 render_duration

Takes a scalar of seconds and renders them as a string.  If you are subclassing
this plugin to add color coding, for example, you just need to override this
method.

=head2 wrap

(internal) wraps the curl command to get timing data and append the duration.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
