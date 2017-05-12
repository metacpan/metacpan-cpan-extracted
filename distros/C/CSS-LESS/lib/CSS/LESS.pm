package CSS::LESS;

use warnings;
use strict;
use Carp;
use File::Temp qw//;
use IPC::Open3;

use version; our $VERSION = qv('0.0.3');

our @LESSC_PARAMS = qw/ include_paths compress strict_imports
 relative_urls rootpath line_numbers version /;
our %DEFAULT_PARAMS = (
	# Parameters for module
	dont_die		 	=> 0,
	dry_run		 	=> 0,
	path_lessc_bin	=> 'lessc',
	path_tmp			=> undef,
	# Parameters for lessc
	include_paths	=> undef,	# Array
	compress		=> 'false',	# Bool
	strict_imports	=> 'false',	# Bool
	relative_urls	=> 'false',	# Bool
	rootpath		=> undef,	# String (URL)
	line_numbers		=> undef,	# String ('comments', 'mediaquery', 'both', or undef)
);

sub new {
	my ($class, %params) = @_;
	my $s = bless({}, $class);

	# Proceess for parameters of constructor
	foreach ( keys %DEFAULT_PARAMS ) {
		if(defined $params{$_}){
			$s->{$_} = $params{$_};
		} else {
			$s->{$_} = $DEFAULT_PARAMS{$_};
		}
	}

	$s->{last_error} = undef;
	$s->{is_lessc_installed} = undef;

	return $s;
}

# Ccompile a less style-sheet (return: Compiled CSS style-sheet)
sub compile {
	my ($s, $buf, %params) = @_;

	unless (defined $s->{is_lessc_installed} ) {
		if($s->is_lessc_installed() == 0 && $s->{dont_die} == 0) {
			die('lessc is not installed');
		}
	}

	unless (%params) {
		%params = ();
	}

	# Process for parameters (Set property in instance)
	foreach ( keys %DEFAULT_PARAMS ) {
		if(!defined $params{$_} && defined $s->{$_}){ # Not defined on params AND defined on member of $self
			$params{$_} = $s->{$_};
		}
	}
	$params{content} = $buf;

	# Compile less to css
	return $s->_exec_lessc(%params);
}

# Get last error
sub last_error {
	my $s = shift;
	return $s->{last_error};
}

# Check for lessc has installed
sub is_lessc_installed {
	my $s = shift;

	if($s->{dry_run}){ # Dry run
		return 1;
	}

	my $lessc_ver;
	eval {
		$lessc_ver = $s->_exec_lessc(version => undef);
	}; if($@) { return 0; }
	if(defined $lessc_ver && $lessc_ver =~ /^lessc .*(LESS Compiler).*/i) {
		$s->{is_lessc_installed} = 1;
		return 1;
	}
	return 0;
}

# Execute a command with lessc
sub _exec_lessc {
	my ($s, %options) = @_;

	# Prepare a command
	my ($cmd_args_ref, $path_tmpfile) = $s->_generate_cmd_lessc(%options);
	my @cmd_args = @{$cmd_args_ref};

	# Execute a command

	if($s->{dry_run}){ # Dry run
		$" = ' ';
		return "@cmd_args"; # return generated command
	}

	my ($fh_in, $fh_out, $fh_err);
	#open $fh, '-|', @cmd_args, '2>&1' or die('Can not open a pipe to:'. $s->{path_lessc_bin});
	my $pid = IPC::Open3::open3($fh_in, $fh_out, 0, @cmd_args);
	my ($ret);
	while (my $l = <$fh_out>) {
		$ret .= $l;
	}
	waitpid($pid, 0);

	# Error process
	if($? != 0){
		$s->{last_error} = $ret;
		unless($s->{dont_die}){
			if(defined $ret){
				die ('Compile error: '. $ret);
			} else {
				die ('Compile error: Unknown');
			}
		}
	}
	# Delete tmp file
	if(defined $path_tmpfile){
		unlink($path_tmpfile);
	}

	return $ret;
}

# Generate a command for lessc (Return: \@args, $path of temp-file)
sub _generate_cmd_lessc {
	my ($s, %options) = @_;
	my @cmd_args = ();

	# Execute path
	push(@cmd_args, $s->{path_lessc_bin});

	# Process for content
	my $path_tmpfile;
	if(defined $options{content}) {
		my $content = $options{content};
		delete $options{content};

		my $tempfh;
		($tempfh, $path_tmpfile) = File::Temp::tempfile(DIR => $s->{path_tmp});
		print $tempfh $content;
		close($tempfh);

		push(@cmd_args, $path_tmpfile);
	}

	# Process for include paths
	if(defined $options{include_paths}){
		if(@{$options{include_paths}} <= 1){
			push(@cmd_args, '--include-path='.$options{include_paths}->[0]);
		} else {
			my $paths = '--include-path=';
			{
				local $" = ':';
				$paths .= "@{$options{include_paths}}";
			}
			$paths .= '';
			push(@cmd_args, $paths);
		}
		delete $options{include_paths};
	}

	# Process for other parameters
	foreach my $key (@LESSC_PARAMS) {
		if(defined $options{$key} && (!defined $DEFAULT_PARAMS{$key} || $DEFAULT_PARAMS{$key} ne 'false')) {
			my $arg_name = $key;
			$arg_name =~ s/\_/\-/g;
			push(@cmd_args, "--".$arg_name."=".$options{$key});
		} elsif(defined $options{$key} && ($options{$key} eq 'false' || $options{$key} == '0') && $DEFAULT_PARAMS{$key} eq 'false') {
			# Do not anything	
		} elsif(exists $options{$key}){
			my $arg_name = $key;
			$arg_name =~ s/\_/\-/g;
			push(@cmd_args, "--".$arg_name);
		}
	}

	push(@cmd_args, '--verbose');
	push(@cmd_args, '--no-color');
	# Return a args (with command path) and a path of temp-file
	return (\@cmd_args, $path_tmpfile);
}

1;
__END__
=head1 NAME

CSS::LESS - Compile LESS stylesheet files (.less) using lessc

=head1 SYNOPSIS

  use CSS::LESS;
  # Compile a single LESS stylesheet
  my $less = CSS::LESS->new();
  my $css = $less->compile('a:link { color: lighten('#000000', 10%); }');
  print $css."\n";

  # Compile a LESS stylesheets with using @include syntax of LESS.
  $less = CSS::LESS->new( include_paths => ['/foo/include/'] );
  $css = $less->compile('@import (less) 'bar.less'; div { width: 100px; }');
  print $css."\n";

This module has released as an alpha version.

=head1 REQUIREMENTS

=head2 lessc

It must installed, because this module is wrapper of "lessc".

You can install "lessc" using "npm" (Node.js Package Manager).

  $ npm install -g less
  $ lessc -v
  lessc x.x.x (LESS Compiler) [JavaScript]

=head1 INSTALLATION (from GitHub)

  $ git clone git://github.com/mugifly/p5-CSS-LESS.git
  $ cpanm ./p5-CSS-LESS

=head1 METHODS

=head2 new ( [%params] )

Create an instance of CSS::LESS.

=head3 %params : 

=over 4

=item C<include_paths>

Path of include .less files. 

This paths will be used for the @include syntax of .less stylesheet.

Use case of example:

  # File-A of LESS stylesheet
  # This file will be set as content when calling a 'compile' method.
  @include (less) 'foo.less';
  ~~~~

  # File-B of LESS stylesheet
  # This file was already saved to: /var/www/include/foo.less
  div {
    width: (100+200)px;
  }
  ~~~~

  # Example of script
  my less = CSS::LESS->new( include_paths => [ '/var/www/include/' ] )
  my $css = $less->compile( File-A ); # Let compile the File-A.
  print $css."\n"; # It includes the File-B, and will be compiled.

=item C<compress>

Compress a compiled style-sheet. It means removing some whitespaces using lessc. (default: 0)

Avaiable value: 1 or 0. This item is same as parameter of lessc. 

=item C<strict_imports>

Force evaluation of imports. (default: 0)

Avaiable value: 1 or 0. This item is same as parameter of lessc.

=item C<relative_urls>

Re-write relative urls to the base LESS stylesheet. (default: undef)

Avaiable value: 1 or 0. This item is same as parameter of lessc.

=item C<rootpath>

Set rootpath for url rewriting in relative imports and urls. (default: undef)

This item is same as parameter of lessc.

=item C<line_numbers>

Outputs filename and line numbers. (default: undef)

Avalable value: 'comments', 'mediaquery', 'both', undef.

This item is same as parameter of lessc.

=item C<lessc_path>

Path of LESS compiler (default: 'lessc' on the PATH.)

=item C<dry_run>

Dry-run mode for debug. (default: 0)

=item C<dont_die>

When an errors accrued, don't die. (default: 0)

=item C<tmp_path>

Path of save for temporally files. (default: '/tmp/'' or other temporally directory.)

=back

=head2 compile ( $content [, %params] )

Parse a LESS (.less) stylesheet, and compile to CSS (.css) stylesheet.

In addition, If you would prefer to compile from a file, firstly, 
please read a file with using the "File::Slurp" module or open method as simply.
Then, parse it with this 'compile' method.

=head3 $content

Content of LESS (.less) stylesheet.

=head3 %params

This item is optional. You can use parameters same as %params of new(...) method.

=head2 is_lessc_installed ( )

Check for lessc has installed.

=head2 last_error ()

Get a message of last error. (This method is useful only if 'dont_die' parameter is set when initialized an instance.)

=head1 SEE ALSO

L<https://github.com/mugifly/p5-CSS-LESS> - Develop on GitHub. Your feedback is highly appreciated.

L<CSS::LESSp> - LESS-parser by native perl implementation.

L<CSS::Sass>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Masanori Ohgita (http://ohgita.info/).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
