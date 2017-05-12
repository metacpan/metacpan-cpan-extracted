package Config::Tiny::Singleton;
use strict;

our $VERSION = 0.02;

use base qw|
	Config::Tiny
	Class::Singleton
	Class::Data::Inheritable
|;

__PACKAGE__->mk_classdata($_) for qw/file errstr/;

sub _new_instance {
	my $class = shift;
	my $file  = $class->file;
	unless($file){
		require Carp;
		Carp::croak "set file before creating instance.";
	}
	return $class->read($file);
}

sub _error {
	my($self, $msg) = @_;
	$self->errstr($msg);
	undef;
}

1;
__END__

=head1 NAME

Config::Tiny::Singleton - singleton-pattern implementation for Config::Tiny

=head1 SYNOPSIS

	package MyProj::Config;
	use base qw/Config::Tiny::Singleton/;
	__PACKAGE__->file('/your/project/conf.file');
	1;

	package main;
	use MyProj::Config;

	my $var = MyProj::Config->instance->{section1}{key1};
	...

	# and in another package,

	package MyProj::Hoge;
	use MyProj::Config;
	my $var2 = MyProj::Config->instance->{section2}{key2};

=head1 DESCRIPTION

You may make many modules and some config-files when you build 
large applications. There are several ways to handle configs.
One is to create new config-object in each packages that need
data set in config-files. However, this will make your app's
performance pretty bad.
Second is to let your context-object to keep your config-object.
But your application become larger and larger, it'll be too hard to
let your context to handle all configs.
And third is, this is better, to implement singleton-pattern.
Try that, and now you only need to call your configs instance method
in your package where you want to use it in.

=head1 SEE ALSO

L<Config::Tiny>, L<Class::Singleton>

=head1 AUTHOR

Lyo Kato E<lt>kato@lost-season.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

