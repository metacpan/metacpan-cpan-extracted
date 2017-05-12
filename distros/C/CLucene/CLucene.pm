# CLucene.pm
#
# Copyright(c) 2005 Peter Edwards <peterdragon@users.sourceforge.net>
# All rights reserved. This package is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

package CLucene;

our $VERSION = '1.00';

use CLuceneWrap;

use strict;
use warnings;

use Carp;
use File::Path;

sub new
{
	my $class = shift;
	my $this = {
		# public
		path			=> undef,
		create		=> 1,
		# parameters
		@_,
		# private
		resource		=> undef,
		};
	bless($this,$class);
	$this->init;
	$this;
}

sub init
{
	my $this = shift;
}

sub open
{
	my $this = shift;
	my %arg = @_;
	my $path = $arg{path} || $this->{path} || confess "path undefined";
	my $create = anyof ( $arg{create}, $this->{create}, 0 );

	$this->{resource} = CLuceneWrap::CL_OPEN ( $path, $create )
		or confess "Failed to CL_OPEN $this->{path} create $create errstr ".$this->errstrglobal();

	$this->{path} = $path;
	$this;
}

sub close
{
	my $this = shift;
	confess unless $this->{resource};
	my $rv = CLuceneWrap::CL_CLOSE($this->{resource})
		or confess "Failed to CL_CLOSE";
	$this->{resource} = undef;
	$rv;
}

sub empty
{
	my $this = shift;
	$this->open(@_) unless $this->{resource};
	$this->close;
	rmtree($this->{path}) if $this->{path};
}

sub reload
{
	my $this = shift;
	confess unless $this->{resource};
	my $rv = CLuceneWrap::CL_RELOAD($this->{resource})
		or confess "Failed to CL_RELOAD";
	$rv;
}

sub optimize
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_OPTIMIZE($this->{resource});
}

sub delete
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $query = $arg{query} || confess "query expected";
	my $field = $arg{field} || confess "field expected";
	CLuceneWrap::CL_DELETE($this->{resource},$query,$field);
}

sub errstr
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_ErrStr1($this->{resource});
}

sub errstrglobal
{
	my $this = shift;
	CLuceneWrap::CL_ErrStrGlobal1();
}

sub new_document
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_NEW_DOCUMENT($this->{resource});
}

# add field from string
sub add_field
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $field = $arg{field} || confess "field undefined";
	my $value = $arg{value}; confess "value undefined" unless defined $value;
	my $vallen = anyof( $arg{length}, length($value) ); # length needs to be specified when nul chars in buffer
	my $store = anyof( $arg{store}, 1 );
	my $index = anyof( $arg{index}, 1 );
	my $token = anyof( $arg{token}, 1 );
	CLuceneWrap::CL_ADD_FIELD($this->{resource}, $field, $value, $vallen, $store, $index, $token);
}

# add a date field
sub add_date
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $field = $arg{field} || confess "field undefined";
	my $valuetime = 0 + anyof( $arg{value}, 0 );
	my $store = anyof( $arg{store}, 1 );
	my $index = anyof( $arg{index}, 1 );
	my $token = anyof( $arg{token}, 1 );
	CLuceneWrap::CL_ADD_DATE($this->{resource}, $field, $valuetime, $store, $index, $token);
}

# add field from file; you get it back using getfield
sub add_file
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $field = $arg{field} || confess "field undefined";
	my $value = $arg{filename} || confess "filename undefined";
	my $store = anyof( $arg{store}, 1 );
	my $index = anyof( $arg{index}, 1 );
	my $token = anyof( $arg{token}, 1 );
	CLuceneWrap::CL_ADD_FILE($this->{resource}, $field, $value, $store, $index, $token);
}

sub insert_document
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_INSERT_DOCUMENT($this->{resource});
}

# returns document info or on error returns empty string and sets globalerrstr
sub document_info
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_Document_Info1($this->{resource});
}

sub search
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $query = $arg{query} || confess "query undefined";
	my $field = $arg{field} || confess "field undefined";
	CLuceneWrap::CL_SEARCH($this->{resource},$query,$field);
	
}

sub searchmultifields
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $query = $arg{query} || confess "query undefined";
	my $fields_aptr = $arg{fields_aptr} || confess "fields_aptr undefined";
	confess "no fields" unless scalar @$fields_aptr > 0;
	CLuceneWrap::CL_SEARCHMULTIFIELDS($this->{resource}, $query, @$fields_aptr, scalar @$fields_aptr);
}

sub searchmultifieldsflagged
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $query = $arg{query} || confess "query undefined";
	my $fields_aptr = $arg{fields_aptr} || confess "fields_aptr undefined";
	confess "no fields" unless scalar @$fields_aptr > 0;
	my $flags_aptr = $arg{flags_aptr} || confess "flags_aptr undefined";
	confess "fields_aptr and flags_aptr must have same number of elements"
		unless scalar @$fields_aptr == scalar @$flags_aptr;
	#CLuceneWrap::CL_SEARCHMULTIFIELDS_FLAGGED($this->{resource}, $query, @fields, $len, @flags);
	my $flags = "";
	for ( 0..scalar @$fields_aptr -1 )
	{
		my $flag = $flags_aptr->[$_] || "";
#        static const l_byte_t NORMAL_FIELD     = 0;
#        static const l_byte_t REQUIRED_FIELD   = 1;
#        static const l_byte_t PROHIBITED_FIELD = 2;
		$flag = "0" unless $flag eq "0" || $flag eq "1" || $flag eq "2";
		$flags .= $flag;
	}
	CLuceneWrap::CL_SearchMultiFieldsFlagged1($this->{resource}, $query, $fields_aptr, scalar @$fields_aptr, $flags);
}

sub search_info
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_Search_Info1($this->{resource});
}

sub hitcount
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_HITCOUNT($this->{resource});
}

sub hitscore
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_HITSCORE($this->{resource});
}

sub nexthit
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_NEXTHIT($this->{resource});
}

sub gotohit
{
	my $this = shift;
	my $hitnum = shift;
	confess unless defined $hitnum && $hitnum >= 0;
	confess unless $this->{resource};
	CLuceneWrap::CL_GOTOHIT($this->{resource},$hitnum);
}

sub clearsearch
{
	my $this = shift;
	confess unless $this->{resource};
	CLuceneWrap::CL_CLEARSEARCH($this->{resource});
}

sub getfield
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $field = $arg{field} || confess "field undefined";
	my $rv = CLuceneWrap::CL_GetField1($this->{resource},$field);
	($rv, $CLuceneWrap::val, $CLuceneWrap::val_len);
}

sub getdatefield
{
	my $this = shift;
	confess unless $this->{resource};
	my %arg = @_;
	my $field = $arg{field} || confess "field undefined";
	CLuceneWrap::CL_GETDATEFIELD($this->{resource}, $field);
}

sub unlock
{
	my $this = shift;
	my %arg = @_;
	my $directorypath = $arg{directorypath} || confess "directorypath undefined";
	CLuceneWrap::CL_UNLOCK($directorypath);
}

sub cleanup
{
	my $this = shift;
	CLuceneWrap::CL_CLEANUP();
}

sub highlight
{
	my $this = shift;
	my %arg = @_;
	my $text = $arg{text} || confess "text unset";
	my $text_is_filename = $arg{text_is_filename} ? 1 : 0;
	CLuceneWrap::CL_Hightlight1($this->{resource}, $text, $text_is_filename);
}

sub highlight_x
{
	my $this = shift;
	my %arg = @_;
	my $text = $arg{text} || confess "text unset";
	my $text_is_filename = $arg{text_is_filename} ? 1 : 0;
	my $sep = $arg{separator} || confess;
	my $max_frags = $arg{max_fragments} || 3;
	my $fragment_size = $arg{fragment_size} || confess;
	my $type = int($arg{type});
	my $html_start = $arg{html_start} || confess;
	my $html_end = $arg{html_end} || confess;
	CLuceneWrap::CL_Hightlight1($this->{resource}, $text, $text_is_filename, $sep, $max_frags, $fragment_size, $type, $html_start, $html_end);
}

# values for flag byte entries
sub NORMAL_FIELD		{ 0 } ;
sub REQUIRED_FIELD	{ 1 } ;
sub PROHIBITED_FIELD	{ 2 } ;

#---

# set if set
sub sis
{
	$_[0] = $_[1] if defined $_[1];
}

# select first defined in list
sub anyof
{
	for (@_)
	{
		return $_ if defined $_;
	}
	undef;
}

1;
__END__

=head1 NAME

CLucene - Perl interface to CLucene C++ search engine

=head1 SYNOPSIS

  use CLucene;
  my $cl = CLucene->new( path => "./index" );

  # create index
  $cl->open( path => "./index", create => 1 );

  # add document to index
  $cl->new_document;
  $cl->add_field( field => "ref", value => "doc1");
  $cl->add_field( field => "cnt", value => "some content");
  $cl->add_date ( field => "add_dt", value => time );
  $cl->insert_document or confess "Failed to insert document";
  $cl->close;

  # search index
  $cl->open( path => "./index", create => 0 );
  $cl->search( query => "some", field => "cnt" ) or confess "Search failed";
  my $hitcount = $cl->hitcount;
  while ($hitcount--)
  {
    (my $ret,my $valref,my $valreflen) = $cl->getfield( field => "ref" );
  	 confess "Failed getfield ref" unless $ret;
  	 ($ret,my $valcnt,my $valcntlen) = $cl->getfield( field => "cnt" );
    confess "Failed getfield cnt" unless $ret;
    my $valadddt = $cl->getdatefield( field => "add_dt" )
      or confess "Failed getdatefield add_dt";
    my $hitscore = $cl->hitscore;
    print("Document: ref: [$valreflen] $valref, cnt: [$valcntlen] $valcnt, add_dt: $valadddt, hitscore: $hitscore\n");
    $cl->nexthit;
  }
  $cl->close;

  # multi field search
  $cl->searchmultifieldsflagged( query => "some", fields_aptr => ["cnt"],
      flags_aptr => [ $cl->NORMAL_FIELD ] )
    or confess "searchmultifieldsflagged failed";


=head1 ABSTRACT

Index and search documents across one or more fields using the CLucene
fulltext search engine, a C++ version of the Java Lucene search engine.

=head1 DESCRIPTION

A perl interface to the CLucene C++ port of the Java Lucene search engine.
See the documentation with CLucene http://sourceforge.net/projects/clucene/
and Lucene http://jakarta.apache.org/lucene/ for further details.

=head1 SEE ALSO

htDig - http://www.htdig.org/

Plucene - http://search.cpan.org/perldoc?Plucene

Search::FreeText - http://search.cpan.org/~snkwatt/Search-FreeText-0.05/

GNU mifluz - http://www.gnu.org/software/mifluz/

=head1 AUTHOR

Peter Edwards

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Peter Edwards <peterdragon@users.sourceforge.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
  
=cut
