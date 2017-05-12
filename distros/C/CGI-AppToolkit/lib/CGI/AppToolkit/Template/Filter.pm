package CGI::AppToolkit::Template::Filter;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Template::Filter::VERSION = '0.05';

require 5.004;
use strict;
use Carp;

sub new {
	my $self = bless {}, shift;
	$self->init(@_);
	$self
}

sub init {

}

1;

__DATA__

=head1 NAME

B<CGI::AppToolkit::Template::Filter> - A superclass for C<CGI::AppToolkit::Template> filters

=head1 DESCRIPTION

B<CGI::AppToolkit::Template::Filter> is intended for subclassing and overriding it's C<filter()> method.

C<filter()> is called as an object with two parameters. The first parameter (after the object reference) is a hashref of the arguments specified in the calling template. The second parameter is the value to be 'filtered.'

=head2 Provided Filters

In addition to being able to write your own filters easily, C<CGI::AppToolkit> comes with several filters:

=over 4

=item B<BR> - Adds C<E<lt>BRE<gt>> tags (or the first parameter passed) to the end of every line.

=item B<HTML> - Escapes HTML entities into their &whatever; form.

=item B<URL> - Escapes the given text for safe use in URLs. If the first parameter is passed as non-zero then spaces are translated to pluses (C<+>) instead of C<%20>.

=item B<Money> - Reformats numbers as 'money.' The first parameter is a C<sprintf()> format. It defaults to C<%.2f>. (NOTE: This can be used as a general C<sprintf()> filter.)

=item B<Abs> - Calls C<abs()> in the given number, making it positive. If the first parameter is true, then it makes it negative.

=back

=head1 SYNOPSIS

This is the complete code of C<CGI::AppToolkit::Template::Filter::BR>.

  package CGI::AppToolkit::Template::Filter::BR;
  
  $VERSION = '0.05';
  
  require 5.004;
  use Carp;
  use base 'CGI::AppToolkit::Template::Filter';
  use strict;
  
  sub filter {
    my $self = shift;
    my $args = shift;
    my $text = shift;
    
    my $br = ref $args && @$args ? $args->[0] : '<br>';
    
    $text =~ s/(\r?\n)/$br\1/g;
    $text
  }
  
  1;

=cut