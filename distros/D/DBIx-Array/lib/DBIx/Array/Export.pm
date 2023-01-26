package DBIx::Array::Export;
use base qw{DBIx::Array};
use strict;
use warnings;

our $VERSION='0.65';
our $PACKAGE=__PACKAGE__;

=head1 NAME

DBIx::Array::Export - Extends DBIx::Array with convenient export functions

=head1 SYNOPSIS

  use DBIx::Array::Export;
  my $dbx=DBIx::Array::Export->new;
  $dbx->connect($connection, $user, $pass, \%opt); #passed to DBI

=head1 DESCRIPTION

=head1 USAGE

=head1 METHODS (Export)

=head2 xml_arrayhashname

Returns XML given an arrayhashname data structure
 
  $dbx->execute(q{ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS"Z"'});
  my @arrayhashname=$dbx->sqlarrayhashname($sql);
  my $xml=$dbx->xml_arrayhashname(data    => \@arrayhashname,
                                  comment => "Text String Comment",
                                  uom     => {col1=>"min", col2=>"ft"});

=cut

sub xml_arrayhashname {
  my $self=shift;
  my $opt={@_};
  my $data=$opt->{'data'} || [];
  $data=[] unless ref($data) eq "ARRAY";
  my $uom=$opt->{'uom'} || {};
  $uom={} unless ref($uom) eq "HASH";

  my $header=shift(@$data);
  foreach (@$data) {
    foreach my $key (keys %$_) {
      if (defined($_->{$key})) {
        $_->{$key}=[$_->{$key}];  #This is needed for XML::Simple to make pretty XML.
      } else {
        CORE::delete($_->{$key});     #This is a choice that I made but I'm not sure if it's smart
      }
    }
  }
  @$header=map {exists($uom->{$_})? {content=>$_, uom=>$uom->{$_}} : $_} @$header;

  my $module="XML::Simple";
  eval("use $module;");
  if ($@) {
    die("Error: $PACKAGE->xml_arrayhashname method requres $module");
  } else {
    my $xs=XML::Simple->new(XMLDecl=>1, RootName=>q{document}, ForceArray=>1);
    my $head={};
    $head->{'comment'}=[$opt->{'comment'}] if $opt->{'comment'};
    $head->{'columns'}=[{column=>$header}];
    $head->{'counts'}=[{rows=>[scalar(@$data)], columns=>[scalar(@$header)]}];
    return $xs->XMLout({
                         head=>$head,
                         body=>{rows=>[{row=>$data}]},
                       });
  }
}

=head2 csv_arrayarrayname

Returns CSV given an arrayarrayname data structure

  my $csv=$dbx->csv_arrayarrayname($data);

=cut

sub csv_arrayarrayname {
  my $self=shift;
  my $data=shift;
  return join "", map {&_join_csv($self->_csv, @$_)} @$data;

  sub _join_csv {
    my $csv=shift;
    my $status=$csv->combine(@_);
    return $status ? $csv->string."\r\n" : (); #\r\n per RFC 4180
  }
}

=head2 csv_cursor

Writes CSV to file handle given an executed cursor (with header row from $sth)

  binmode($fh);
  $dbx->csv_cursor($fh, $sth);

Due to portability issues, I choose not to force the passed file handle into binmode.  However, it IS required!  For most file handle objects you can run binmode($fh) or $fh->binmode;

=cut

sub csv_cursor {
  my $self=shift;
  my $fh=shift;
  my $sth=shift;
  $self->_csv->print($fh, scalar($sth->{'NAME'}));
  print $fh "\r\n";
  $self->csvappend_cursor($fh, $sth);
}

=head2 csvappend_cursor

Appends CSV to file handle given an executed cursor (no header row)

  binmode($fh);
  $dbx->csvappend_cursor($fh, $sth);

=cut

sub csvappend_cursor {
  my $self=shift;
  my $fh=shift;
  my $sth=shift;
  my $row=[];
  local $|=0;
  while ($row=$sth->fetchrow_arrayref()) {
    $self->_csv->print($fh, $row);
    print $fh "\r\n";
  }
  $sth->finish;
}

sub _csv {
  my $self=shift;
  $self->{"_csv"}=shift if @_;
  eval("use Text::CSV_XS;");
  die("Error: CSV Export Methods requre Text::CSV_XS") if $@;
  $self->{"_csv"}=Text::CSV_XS->new unless defined $self->{"_csv"};
  return $self->{"_csv"};
}

=head2 xls_arrayarrayname

Returns XLS data blob given an arrayarrayname data structure

  my $xls=$dbx->xls_arrayarrayname("Tab One"=>$data, "Tab Two"=>$data2, ...);

=cut

sub xls_arrayarrayname {
  my $self=shift;
  my $module="Spreadsheet::WriteExcel::Simple::Tabs";
  eval("use $module;");
  if ($@) {
    die("Error: $PACKAGE->xls_arrayarrayname method requres $module");
  } else {
    my $ss=Spreadsheet::WriteExcel::Simple::Tabs->new();
    $ss->add(@_);
    return $ss->content;
  }
}

=head1 TODO

Switch out L<XML::Simple> for L<XML::LibXML::LazyBuilder>

=head1 BUGS

Please open on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

MIT License

Copyright (c) 2023 Michael R. Davis

=head1 SEE ALSO

=head2 Building Blocks

L<XML::Simple>, L<Text::CSV_XS>, L<Spreadsheet::WriteExcel::Simple::Tabs>

=head2 Similar Capabilities

L<Data::Table> see csv and tsv methods, L<Data::Table::Excel>

=cut

1;
