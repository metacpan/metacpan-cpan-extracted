package CGI::Widget::Path;

require 5.005;
use strict;
use vars qw($VERSION);

$VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = ($#_ == 0) ? shift : { @_ };
	$self->{'separator'} = '>' unless defined $self->{'separator'};
	$self->{'link_last'} = 0 unless ( defined $self->{'link_last'} and $self->{'link_last'} =~ /^(0|1)$/ );
	$self->{'link'} = 1 unless ( defined $self->{'link'} and $self->{'link'} =~ /^(0|1)$/ );
	bless $self,$class;
	if ( $self->{'path'} ) {
		eval { require File::Spec};
		foreach ( File::Spec->splitdir($self->{'path'}) ) {
			$self->addElem( elems => [
				{ name => $_, wrap => [ { tag => 'a', attr => { 'href' => "$_/" } } ], append => 1 },
				] );
		}
		$self->{elems}->[0]->{'name'} ||= 'root';
	}
	return $self;
}

sub asHTML {
	my ($self,%args) = @_;
	my $str;
	my $tree_path = "$self->{'base_url'}" if $self->{'base_url'};

	for (my $i = 0; $i <= $#{@{$self->{'elems'}}}; $i++)	{
		#next if ( ! exists ${@{$self->{'elems'}}}[$i]{'name'} or ${@{$self->{'elems'}}}[$i]{'name'} eq '' ) ;
		next unless ( exists ${@{$self->{'elems'}}}[$i]{'name'} and ${@{$self->{'elems'}}}[$i]{'name'} ne '' ) ;
		my $element = ${@{$self->{'elems'}}}[$i]{'name'};
		$str .= $self->{'separator'} if $i > 0;
		foreach my $wrap( @{${@{$self->{'elems'}}}[$i]{'wrap'}} ) {
			unless ( $wrap->{'tag'} =~ /^a$/i and ( ($i == $#{@{$self->{'elems'}}} and ! $self->{'link_last'}) || ! $self->{'link'} ) ) {
				$element = '<' . $wrap->{'tag'} . ($wrap->{'attr'} ? ' ' . join ' ', map {"$_=\"" . ($_ =~ /^href$/i ? (${@{$self->{'elems'}}}[$i]{'append'} ? ($tree_path .= $wrap->{'attr'}{$_}) : "$self->{'base_url'}$wrap->{'attr'}{$_}") : "$wrap->{'attr'}{$_}") . '"'} keys %{$wrap->{'attr'}} : '' ) . '>' . $element . '</' . $wrap->{'tag'} . '>';
			}
		}
		$str .= $element;
	}
	$self->{'out'} = $str;
	return $self->{'out'};
}

sub addElem {
	my ($self,%args) = @_;
	$args{'position'} = ($#{@{$self->{'elems'}}} + 1) if ! defined $args{'position'};
	splice(@{$self->{'elems'}}, $args{'position'}, 0, @{$args{'elems'}});
	return scalar @{$self->{'elems'}};
}

sub deleteElem {
	my ($self,%args) = @_;
	$args{'position'} = $#{@{$self->{'elems'}}} if ! defined $args{'position'};
	$args{'lenght'} ||= 1;
	splice(@{$self->{'elems'}}, $args{'position'}, $args{'lenght'});
	return scalar @{$self->{'elems'}};
}

sub errstr {
	my $self = shift;
	$self->{'errstr'};
}

1;

__END__

=pod 

=head1 NAME

CGI::Widget::Path - Simple HTML navigation path bar builder

=head1 SYNOPSIS

   use CGI::Widget::Path;
   my $path = new CGI::Widget::Path( 
      separator => ' > ',
      base_url  => 'http://www.foo.com',
      link      => 1,
      link_last => 1,
   );
   $path->addElem( elems => [
      { name => 'One', wrap => [ { tag => 'a', attr => { 'href' => 'url1' } ], append => 1 },
      { name => 'Two', wrap => [ { tag => 'a', attr => { 'href' => 'url2' } ], append => 1 },
      ] );
   print $path->asHTML;

=head1 DESCRIPTION

CGI::Widget::Path lets you build a navigation path bar (you know: "You are
here: Home > some > page") in order to put it in your HTML pages.

This module is very simple but it can be useful if you create a path component
at the top of your application and share it among all sub-pages.

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
higher.

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 DEPENDENCIES

No thirdy-part modules are required.

=head1 CONSTRUCTOR

=over 4

=item * new( %args )

It's possible to create a new C<CGI::Widget::Path> by invoking the C<new>
method. Parameters are passed as hash array:

=over 4

=item C<base_url> string

Adds this string at the beginning of each link.

=item C<link> boolean

Links all path items wrapped by an 'a' tag. Default is C<1>.

=item C<link_last> boolean

Links last path item. Default is C<0>.

=item C<separator> string

Sets separator between path items. Default is '>'

=item C<path> string

Uses C<path> as a file system path and builds automatically a path tree
array (see EXAMPLES section).

=item C<elems> array reference

This parameter is an anonymous array. Each element (an hash reference)
represents each path item. You can also set or add (other) path elements by
calling C<addElem> method.

See C<elems> argument in C<addElem> method for more informations.

=back

=back

=head1 METHODS

C<CGI::Widget::Path> has following public methods:

=over 4

=item * addElem( %args )

Adds an element into path tree. Parameters are passed as hash array:

=over 4

=item C<position> number

Sets position where to start adding new element(s). New path elements
are appended at the end of array if none.

=item C<elems> array reference

This argument is the same of C<elems> contructor argument, that is an anonymous
array o hash reference. Each element is a anonymous hash with following keys:

=over 4

=item C<name> string

The name of path item.

=item C<wrap> array reference

An anonymous array containing HTML tags that will wrap the path item (like tha
'A' tag for links). Each element is a hash reference containg at least 'tag'
key. An optional 'attr' keys can be used in order to set tag's attributes.

=item append

If set to C<1>, the 'href' attribute of 'a' tag will be 'appended' to all other
previous path elements 'href' values. Default is C<0>.

=back

For example:

   elems => [ 
      { name => 'One', wrap => [ { tag => 'a', attr => { 'href' => 'url1', class => 'myclass' } } ], append => 1 },
	]

=back

Returns the number of path elements

=item * deleteElem( %args )

Deletes items from path tree. Parameters are passed as hash array:

=over 4

=item C<position> number

Deletes item, starting from C<position>

=item C<lenght> number

Deletes C<lenght> items. Default value is C<1>.

=back

Returns the number of path elements

=item * asHTML()

Builds and returns HTML path widget. After call it, you can 
use also C<$self-E<gt>{out}> object property in order to retrieve HTML generated code.

=item * errstr()

Returns current error string.

=back

=head1 EXAMPLES

This example creates and renders a path widget from a filesystem path:

   use CGI::Widget::Path;
   # create new path object
   my $path = new CGI::Widget::Path( 
      separator => ' / ', 
      base_url  => 'http://www.foo.com', 
      path => '/one/two/tree/four.txt' 
      );
   # Optionally set root label with 'My Home' (default is 'root')
   $path->{elems}->[0]->{'name'} = 'My Home';
   print $path->asHTML;

This will produce following output:

   <a href="http://www.foo.com/">My Home</a> / <a href="http://www.foo.com/one/">one</a> / 
   <a href="http://www.foo.com/one/two/">two</a> / <a href="http://www.foo.com/one/two/tree/">tree</a> / four.txt

This example creates and renders a path widget from a filesystem path:

   use CGI::Widget::Path;
   # create new path object
   my $path = new CGI::Widget::Path();
   $path->addElem( elems => [
      { name => 'One', wrap => [ { tag => 'a', attr => { 'href' => '/url1', class => 'myclass' } } ], append => 1 },
      { name => 'Two', wrap => [ { tag => 'a', attr => { 'href' => '/url2' } } ], append => 1 },
		{ name => 'Three', wrap => [ { tag => 'a', attr => { 'href' => '/url3' } } ], append => 1 },
      ] );
   print $path->asHTML;

This will produce following output:

   <a href="/url1" class="myclass">One</a>><a href="/url1/url2">Two</a>>Three

This example creates and renders a path widget from current URI:

   # create new path object
   my $path = new CGI::Widget::Path( 
      separator => '/',
      base_url  => 'http://' . $ENV{HTTP_HOST},
      path => $ENV{SCRIPT_NAME} . $ENV{PATH_INFO}
      );
   $path->{elems}->[0]->{name} = 'My Home';
   print $path->asHTML;

=head1 TODO

=over 4

=item * 

Add an OO interface to manage HTML elements (possibly by using HTML::Element,
if installed)

=back

=head1 AUTHORS

Enrico Sorcinelli <enrico@sorcinelli.it>

=head1 BUGS 

This library has been tested by the author with Perl versions 5.005, 5.6.x and
5.8.x on different platforms: Linux 2.2 and 2.4, Solaris 2.6 and 2.7 and
Windows 98.

Send bug reports and comments to: enrico@sorcinelli.it In each report please
include the version module, the Perl version, the Apache, the mod_perl version
and your SO. If the problem is  browser dependent please include also browser
name and version.

Patches are welcome and I'll update the module if any problems will be found.

=head1 SEE ALSO

L<File::Spec|File::Spec>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003,2004 Enrico Sorcinelli. All rights reserved. This program is
free software; you can redistribute it  and/or modify it under the same terms
as Perl itself. 

=cut


