#########################################################
package AnyData::Format::CSV;
#########################################################
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################

=head1 NAME

 AnyData::Format::CSV - tiedhash & DBI/SQL access to CSV data

=head1 SYNOPSIS

 use AnyData;
 my $table = adTable( 'CSV', $filename,'r',$flags );
 while (my $row = each %$table) {
    print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','CSV', $filename,$flags,'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This is a plug-in format parser for the AnyData and DBD::AnyData modules. It will read column names from the first row of the file, or accept names passed by the user.  In addition to column names, the user may set other options as follows:

  col_names   : a comma separated list of column names
  eol         : the end of record mark, \n by default
  quote_char  : the character used to quote fields " by default
  escape_char : the character used to escape the quote char, " by default

If you are using this with DBD::AnyData, put ad_ in front of the flags, e.g.
ad_eol.

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved


=cut


use strict;
use warnings;
use AnyData::Format::Base;
use vars qw( @ISA $VERSION);
@AnyData::Format::CSV::ISA = qw( AnyData::Format::Base );

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $self  = shift ||  {};
    my $s = ${self}->{field_rsep} || ${self}->{field_sep} || q(,);
    my $s1 = $s;
    #$s1 =~ s/\\/\\\\/ if $s1 =~ /\+$/;
    #$s1 =~ s/\+$//;
    #die $s1;
    ${self}->{field_sep}          ||= q(,);
    my $q = ${self}->{quote}      ||= q(");
    my $e = ${self}->{escape}     ||= q(");
    ${self}->{record_sep}         ||= qq(\n);
    $self->{regex} = [
        qr/$q((?:(?:$e$q)|[^$q])*)$q$s?|([^$s1]+)$s?|$s/,
        "$e$q",
        $q
    ];
    return bless $self, $class;
}

sub read_fields {
    my $self = shift;
    my $str  = shift || return undef;
    my @fields = ();
    my $captured;
    my $field_wsep = $self->{field_wsep} || $self->{field_sep};
    if ($self->{trim}) {
        $str =~ s/\s*($field_wsep)\s*/$1/g;
    }
    while ($str =~ m#$self->{regex}->[0]#g) {
         $captured = $+;
         $captured =~ s/$self->{regex}[1]/$self->{regex}[2]/g if $captured;
         last if $captured && $captured eq "\n";
         push(@fields,$captured);
     };
     push(@fields, undef) if substr($str,-1,1) eq $field_wsep;
     return @fields;
}

sub write_fields {
    my $self   = shift;
    my @fields = @_;
    my $str    = '';
    my $field_rsep = $self->{field_rsep} || $self->{field_sep};
    $field_rsep = quotemeta($field_rsep);
    my $field_wsep = $self->{field_sep};
    $field_wsep =~ s/\\//g;
#    if ($self->{ChopBlanks}) {
#        $field_wsep =~ " $field_wsep ";
#    }
    for (@fields) {
        $_ = '' if !defined $_;
        if ($self->{field_sep} eq ',') {
            s/"/""/g;
            s/^(.*)$/"$1"/s if /,/ or /\n/s or /"/;
	}
        $str .= $_ . $field_wsep;
    }
    $str =~ s/$self->{field_sep}$/$self->{record_sep}/;
    return $str;
}
1;



