#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/File/Bind9.pm
#
# $Id: Bind9.pm,v 1.8 2003/02/16 10:15:32 awolf Exp $
# $Revision: 1.8 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:32 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::File::Bind9;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw(@ISA);

use DNS::Config;
use DNS::Config::Server;
use DNS::Config::Statement;

@ISA = qw(DNS::Config::File);

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg, $file, $config) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'FILE' => $file
	};

	$self->{'CONFIG'} = $config if($config);
	
	bless $self, $class;
	
	return $self;
}

sub parse {
	my($self, $file) = @_;
	
	my @lines = $self->read($file);

#	# substitute include statements completely
#	for(my $i=0 ; defined $lines[$i] ; $i++) {
#		if($lines[$i] =~ /^\s*include\s+\"*(.+)\"*\s*\;/i) {
#			my @included = $self->read($1);
#			splice @lines, $i, 1, @included
#		}
#	}
	
	return undef unless(scalar @lines);

	$self->{'CONFIG'} = new DNS::Config() if(!$self->{'CONFIG'});
	
	my $result;

	# Keep track of whether we're in a multi-line comment or not.
	my $in_long_comment = 0;

	# Keep track of which line we're on.  Since we increment this at
	# the end of the loop, don't use 'next' in here.
	my $cntr = 0;
  	for my $line (@lines) {
		if( $in_long_comment ){
			# Remove stray '*' characters.
			$line =~ s/^[^\*]*\*[^\/]//g;

			# See if we find the end.
			if( $line =~ /^[^\*]*\*\// ){
				# We've found the end.  Stip off stuff 
				# leading to it, and reset the flag.
				$line =~ s/^[^\*]*\*\///;
				$in_long_comment=0;
			}else{
				# We're still in the comment.  Make it a
				# normal comment for now.
				$line = "# $line";
			}
		}
	
		# replace lots of space with one space.
  		$line =~ s/\s+/ /g;

		# Remove '//' style comments.
  		$line =~ s/\/\/.*$//g;

		# Remove '#' style comments.
  		$line =~ s/\#.*$//g;

		# See if we start a possibly long comment
		if( $line =~ /\/\*/ ){
			# This is irritating.
			$in_long_comment = 1;
			if( $line =~ /\/\*[^\*]*\*\// ){
				$in_long_comment = 0;
				$line =~ s/\/\*[^\*]*\*\///g;
			}else{
				# The end isn't on this line.  Cleanup 
				# this line and let it be added.
				$line =~ s/\/\*.*$//g;
			}
		}

		# We need to insert include statements at this point, but
		# we need to know which 'directory' these possible relative-
		# path files live in.  So we partially parse the lines that
		# we've got so far.  Fortunately, you cannot invoke include
		# within a statement.  I hope.

		# This regex is also overly greedy.
		if( $line =~ /^(.*)(include)\s+(\S+.*)\;(.*)$/ ){
			my $laststuff = $1;
			my $incfile = $3;
			my $nextstuff = $4;
			
			# Put the final stuff to the @result.
			$result .= $laststuff;

			# Put this lot of stuff to the CONFIG
			$self->parse_real( $result );

			# reset $result
			$result = undef;

			# Get the directory now.
			my $tdir = $self->_options_dir();

			# Clean up the included file.
			if( $incfile =~ /^\"(.+)\"$/ ){
				$incfile = $1;
			}else{
				# Might need to revisit this.
			}

			# Finally, why we're doing this.  If this isn't
			# an absolute path, then it must be a relative 
			# path.  If it is relative, prepend the directory
			# name so read() can actually find the file.
			if( $incfile !~ /^\s*\// && defined( $tdir ) ){
				$incfile = $tdir . "/" . $incfile;
			}

			# Read in the included file, and put it at the start
			# of the @lines that we have.
			my @included = $self->read($incfile);
			
			# I think this splice is right - insert after the 
			# current line.
			splice @lines, $cntr+1, 0, @included;

			# Restore the stuff after the include line.
			$line = $nextstuff;
		}
		
		# Add the current line to the meta-results.	
		$result .= $line;
		$cntr++;
	}

	# Parse the remaining stuff (we might have already done this with 
	# stuff before an include file.)
	$self->parse_real( $result );
		
	return $self;
}

sub parse_real() {
	my( $self, $result ) = (@_);
	return( undef ) unless( defined( $result ) );

	my $tree = &analyze_brackets($result);
	my @res = &analyze_statements(@$tree);

	foreach my $temp (@res) {
		my @temp = @$temp;
		my $type = shift @temp;

		my $statement;

		eval {
			my $tmp = 'DNS::Config::Statement::' . ucfirst(lc $type);

			if ( eval "require $tmp" ){
				$statement = $tmp->new();
				$statement->parse_tree(@temp);
			}else{
				# Doesn't exist.
				warn "Require of $tmp failed\n";
			}
		};

		if($@) {
			#warn $@;
			
			$statement = DNS::Config::Statement->new();
			$statement->parse_tree($type, @temp);
		}

		$self->{'CONFIG'}->add($statement);
	}
}

# Iterate through the config, and pull the directory statement.
sub _options_dir() {

	my $self = shift;

	my @statements = $self->config->statements();

	my $retdir = undef;

	foreach my $statement( @statements ){
		my $tref = ref( $statement );
		next unless( $tref eq "DNS::Config::Statement::Options" );

		$retdir = $statement->directory();	
	}

	return( $retdir );
}

sub dump {
	my($self, $file) = @_;
	
	$file = $file || $self->{'FILE'};

	return undef unless($file);
	return undef unless($self->{'CONFIG'});
	
	if($file) {
		if(open(FILE, ">$file")) {
			my $old_fh = select(FILE);

			map { $_->dump() } $self->config()->statements();
			
			select($old_fh);
			close FILE;
		}
		else { return undef; }
	}
	else {
		map { $_->dump() } $self->config()->statements();
	}
	
	return $self;
}

sub config {
	my($self) = @_;
	
	return($self->{'CONFIG'});
}

sub analyze_brackets {
	my($string) = @_;
	
	my @chars = split //, $string;

	my $tree = [];
	my @chunks;
	my @stack;

	my %matching = (
		'(' => ')',
		'[' => ']',
		'<' => '>',
		'{' => '}',
	);

	for my $char (@chars) {
		if(grep {$char eq $_} keys(%matching)) {
			my $temp = [];
			push @$tree, $temp;
			push @chunks, $tree;
			push @stack, $matching{$char};
			$tree = $temp;
		}
		elsif(grep {$char eq $_} values(%matching)) {
			my $expected = pop @stack;
			die "Invalid order !\n" if((!defined $expected) || ($char ne $expected));
			$tree = pop @chunks;
			die "Unmatched closing !\n" if(!ref($tree));
		}
		else {
			my $noe = scalar(@$tree);
			
			if((!$noe) || (ref($$tree[$noe-1]) eq 'ARRAY')) {
				push @$tree, ($char);
			}
			else {
				$$tree[$noe-1] .= $char;
			}
		}
	}

	die "Unbalanced !\n" if(scalar @stack);

	return($tree);
}

sub analyze_statements {
	my(@array) = @_;
	my @result;
	my $full;
	
	for my $line (@array) {
		if(!ref($line)) {
			$line =~ s/\s*\;\s*/\;/g;

			my(@parts) = split /;/, $line, -1;

			shift @parts if(!$parts[0]);

			if($parts[$#parts-1] eq '') {
				$full = 1;
				pop @parts;
			}
			else {
				$full = 0;
			}

			for my $temp (@parts) {
				if($temp) {
					$temp =~ s/^\s*//g;
					
					my @chunks = split / /, $temp;

					push @result, (\@chunks);
				}
			}
		}
		else {
			my @statements = &analyze_statements(@$line);

			my @temp;
			if(!$full) { my $temp = pop @result; @temp = @$temp; }
			push @temp, (\@statements);
			push @result, (\@temp);
		}
	}

	return(@result);
}

1;

__END__

=pod

=head1 NAME

DNS::Config::File::Bind9 - Concrete adaptor class

=head1 SYNOPSIS

use DNS::Config::File::Bind9;

my $file = new DNS::Config::File::Bind9($file_name_string);

$file->parse($file_name_string);
$file->dump($fie_name_string);
$file->debug();

$file->config(new DNS::Config());


=head1 ABSTRACT

This class represents a concrete configuration file for ISCs
Bind v9 domain name service daemon (DNS).


=head1 DESCRIPTION

This class, the Bind9 file adaptor, knows how to write the
information to a file in the Bind9 daemon specific format.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Config>, L<DNS::Config::File>


=cut
