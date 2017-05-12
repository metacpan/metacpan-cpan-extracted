package Class::Serializer;

use warnings;
use strict;

# no imports, thanks
use File::Path ();
use Data::Dump::Streamer ();

=head1 NAME

Class::Serializer - Serializes the in-memory state of a class into code

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This module does its best efforts to serialize the in-memory state of a class
into runable code. For this to actually happen successfully it relies heavily
on L<Data::Dump::Streamer> which, in turn, relies on L<B::Deparse> for 
CODEREF deparsing and other similar tasks. 

B<Please, keep in mind that this module is experimental. 
There are no guarantees whatsoever about the generated code.>

With that said, it should work just fine.

Here's a little a code snippet:

    use Class::Serializer;
    
    # Class::Serializer is Class::Serializer safe
    my $class_code = Class::Serializer->as_string('Class::Serializer');
    
    # writes directly to ClassSerializer.pm
    Class::Serializer->as_file(Class::Serializer => 'ClassSerializer.pm');

=head1 CLASS METHODS

=cut

=head2 as_string($target_class)

Serializes C<$target_class> in-memory state (actually, symbol table entries) 
into perl code and returns it as a string. It will also try to detect possible
dependencies and try to honor them through C<require> statements in the
generated code.

=cut
sub as_string {
	my $class = shift;
	my ($target) = @_;

	my %seen;
	no strict 'refs';
	
	# loads the relevant data structures
	while (my ($entry, $contents) = each %{"${target}::"}) {
		for my $type (qw|SCALAR ARRAY HASH CODE|) {
			if (*{$contents}{$type}) {
				next if ($type eq 'SCALAR' && !defined ${*{$contents}{$type}});
				push(@{$seen{$type}}, ["$entry", *{$contents}{$type}]);
			}
		}
	};
	
	use strict 'refs';
	
	# builds up something suitable to be spoon fed to the dumper
	my (@dump, @names);
	for my $type (qw|ARRAY HASH CODE|) {
		for my $entry (@{$seen{$type}}) {
			push(@dump, $entry->[1]);
			push(@names, '*'.$entry->[0]);
		}
	}

	# Data::Dumper messes everything up with scalars
	for my $entry (@{$seen{SCALAR}}) {
		push(@dump, ${$entry->[1]});
		push(@names, '$'.$entry->[0]);
	}

	my $dump = 
        "package $target;\n" . 
        Data::Dump::Streamer::DumpVars( map { $names[$_], $dump[$_] } 0..$#dump )->Declare(1)->Out() . 
        ';1;';

	my %required = ($target => 1);
	# tries to detect dependencies and loads them through eval 'require Pkg'
	# (eval is used so that errors are not fatal)
	my $require = '';
	while ($dump =~ /(?:package ([\w\:]+);|'([\w\:]+)'\->)/g) {
		my $pkg = $1 || $2;
		unless ($required{$pkg}) {
			$require .= "eval 'require $pkg';\n";
			$required{$pkg} = 1;
		}
	}

	$require . $dump;

}

=head2 as_file($target_class, [$file_name, [$overwrite]])

Serializes C<$target_class> in-memory state into perl code and saves it into 
C<$file_name>, overwriting the file if C<$overwrite> is set to a true value.

If C<$file_name> is not defined, it will be constructed based on the target
class name, relative do the current path. So C<Class::Serializer> would be saved
in Class/Serializer.pm.

If C<$file_name> exists and C<$overwrite> is not set, an exception is thrown. 
An exception is also thrown if the file is not writable.

=cut

sub as_file {
	my $class = shift;
	my ($target, $file_name, $overwrite) = @_;
	
	# constructs the file name, if it's either undef or empty
	unless (defined $file_name && length($file_name)) {
		($file_name = $target) =~ s|::|/|;
		$file_name .= '.pm';
	}

	# creates directories if they don't exist
	if ((my $path = $file_name) =~ s|([\\/])[^\\/]+$|$1|) {
		File::Path::mkpath($path);
	}

	_croak("'$file_name' already exists")
		if (-e $file_name && !$overwrite);

	# writes
	open(my $fh, '>', $file_name) 
		or _croak("couldn't write to '$file_name': $!");

	print $fh $class->as_string($target);

	close $fh;
	
	$file_name;
}

sub _croak {
	require Carp;
	Carp::croak(@_);
}

=head1 CAVEATS

The dependency detecting code is pretty simple and may be not very reliable.

Closures should work just fine as of version 0.04. This feature wasn't tested
extensively, though (it just relies on L<Data::Dump::Streamer> for that).

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author.
If you ask nicely it will probably get fixed or implemented.

=head1 SUPPORT

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Serializer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Serializer>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Serializer>

=back

=head1 SEE ALSO

L<Data::Dump::Streamer>, L<B::Deparse>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::Serializer
