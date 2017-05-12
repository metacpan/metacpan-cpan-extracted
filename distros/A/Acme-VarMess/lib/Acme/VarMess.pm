package Acme::VarMess;

use strict;
use PPI;
use Data::Dumper;
use List::Util qw(shuffle);
use Digest::MD5 qw(md5_hex);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(blow);

our $VERSION = 0.01;


our $DEBUG = 0;

my %symtable;
my @symbol = map{('a'..'z','A'..'Z','_')
		     [int(rand(53))].(time).md5_hex($_)} shuffle 1..65536;
my %invar = map{$_=>1} qw(
			  VERSION
			  EXPORT
			  EXPORT_OK
			  ),0..9,split//,q(ab`!@#$%^&*()+-={};':",./<>?|\\[]);

sub dont_blow {
    %invar = map{$_=>1} @_;
}

sub blow($$;$) {
    my ($src, $outputfile) = @_;
    my $doc;
    if(ref $src){
	$doc = PPI::Document->new($$src);
    }
    else {
	$doc = PPI::Document->load($src);
    }

#print Dumper
    grep{$_->{content}
	 =~
	     s[^(.)(.+)$] # process simple symbol names
	       [$invar{$2} ?
	     $1.$2 : (
		      exists($symtable{$2}) ?
		      $1.$symtable{$2} : 
		      $1.($symtable{$2} = shift @symbol)) ]e;
	       $_}
    grep{
	$_->{content} =~
	    s[^(.+::)(.+)$] # process symbols with full package name
	      [$invar{$2} ?
	       $1.$symtable{$2} :
	       $1.($symtable{$2} = shift @symbol)]e;
	      $_}
	grep{$_ and !$_->isa('PPI::Token::Magic') }
	@{$doc->find('PPI::Token::Symbol')};
	
	print Dumper \%symtable if $DEBUG;
	$doc->prune('PPI::Token::Pod');
	$doc->prune('PPI::Token::Comment');
	
	
	for (@{$doc->find('PPI::Token::Whitespace')}){
	    $_->{content} = ' ' if $_->{content} eq $/;
	}

	$doc->save($outputfile);
}

sub find {
    $symtable{shift()};
}

1;

__END__

=head1 NAME

Acme::VarMess - Blow up your variable names

=head1 SYNOPSIS

  use Acme::VarMess;

  $Acme::VarMess::DEBUG = 1;

  blow(\$source_code, $output_file);

  blow($source_code_file, $output_file);

  dont_blow(@list_of_symbols);

=head1 DESCRIPTION

This module screws up the variables in your source code and replace
them with md5-digest-like strings. It also strips comments and PODs in
your source. There's I<no> warranty that VarMess-ed code still works
normally.

dont_blow() takes a list of symbols that you don't want to be
replaced.

Turn on $Acme::VarMess::DEBUG if you want to see the mapping table.


=head1 THE AUTHOR

Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=head1 SEE ALSO

L<Perl::Tidy> for a completely opposite thing.

=cut
