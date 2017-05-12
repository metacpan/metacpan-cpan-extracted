#############################################################################
## Name:        XMLPerl.pm
## Purpose:     Config::XMLPerl
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-15
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Config::XMLPerl ;
use 5.006 ;

use strict qw(vars);

use vars qw($VERSION @ISA) ;

$VERSION = '0.01' ;

require Exporter;
@ISA = qw(Exporter);

our @EXPORT = qw(config_load) ;
our @EXPORT_OK = @EXPORT ;

###########
# REQUIRE #
###########

  use XML::Smart ;
  use Safe ;

########
# VARS #
########

  use vars qw($CACHE_DELAY) ;

  $CACHE_DELAY = 0 ;
  
  my ( %CACHE , $CACHE_SLEEP , $EVAL_VALUES_COMPARTMENT ) ;
  
################################################################################
  
  my @PERMIT_OPS = qw(
  :base_mem

    null stub pushmark const defined undef

    preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec
    int hex oct abs pow multiply i_multiply divide i_divide
    modulo i_modulo add i_add subtract i_subtract

    left_shift right_shift bit_and bit_xor bit_or negate i_negate
    not complement

    lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp
    slt sgt sle sge seq sne scmp

    substr stringify length ord chr

    ucfirst lcfirst uc lc quotemeta trans chop schop chomp schomp

    match split

    list lslice reverse

    cond_expr flip flop andassign orassign and or xor

    lineseq scope enter leave setstate

    rv2cv

    leaveeval

  
  gvsv gv gelem

  padsv padav padhv padany

  refgen srefgen ref

  time
  sort 
  pack unpack
  ) ;
  
################################################################################


#######
# NEW #
#######

sub new {
  shift ; return config_load(@_) ;
}

###############
# CONFIG_LOAD #
###############

sub config_load {

  if ( my $doc = $CACHE{$_[0]} ) {
     
    if ( (time-$CACHE_SLEEP) > $CACHE_DELAY ) {
      my @stats = stat($_[0]) ;
      if ( $doc->{s} != $stats[7] || $doc->{t} != $stats[9] ) {
        $doc = undef ;
        delete $CACHE{$_[0]} ;
      }
    }
    return $doc->{x} if $doc ;
  }

  my ($data , $file) = read_data($_[0]) ;
  
  $data =~ s/(?:^|\n)[ \t]*#[^\n]+//gs ;
  
  my $xml = XML::Smart->new($data , 'html' ,
  lowtag => 1 ,
  lowarg => 1 ,
  on_char => \&on_char ,
  ) ;
  
  $xml = $xml->cut_root ;

  if ( $file ) {
    my @stats = stat($file) ;
    $CACHE{$file}{x} = $xml ;
    $CACHE{$file}{s} = $stats[7] ;
    $CACHE{$file}{t} = $stats[9] ;
  }
  
  return $xml ;
}

###########
# ON_CHAR #
###########

sub on_char {
  my ( $tag , $pointer , $pointer_back , $cont) = @_ ;
  
  my $data = $$cont ;

  my (@args) = ( $data =~ /[^\n\w]*(\w+[\w:\.]*[ \t]*(?:=>?|->|:)[ \t]*[^\n]+)/gs ) ;
  
  foreach my $args_i ( @args ) {
    $data =~ s/\Q$args_i\E//s ;
    my ($name,$val) = ( $args_i =~ /(\w+[\w:\.]*)[ \t]*(?:=>?|->|:)[ \t]*([^\n]+)/ );
    $val =~ s/\s*,\s*$// ;
    
    if    ( $val =~ /^'([^'\\]*)'$/ ) { $val = $1 ;}
    elsif ( $val =~ /^"([^"\\]*)"$/ ) { $val = $1 ;}
    elsif ( $val =~ /^(?:\{.*?\}|\[.*?\]|'.*?'|".*?")$/ ) { $val = reval($val) ;}
    
    $pointer->{$name} = $val ;
  }
  
  $data =~ s/\s+//gs ;
  
  if ( !$data ) { $$cont = undef ;}
}

#############
# READ_DATA #
#############

sub read_data {
  my $in = shift ;
  my ($data , $file , $fh) ;

  if ( ref($in) eq 'GLOB' ) { $fh = $in ;}
  elsif ( $in !~ /[\r\n]/s && -e $in ) {
    $file = $in ;
    open ($fh,$in) ; binmode($fh) ;
  }
  
  if ( $fh ) {
    1 while( read($fh , $data , 1024*8 , length($data) ) ) ;
  }
  elsif ($in =~ /[<>\r\n]/s) { $data = $in ;}
  
  $data =~ s/\r\n?/\n/gs ;
  
  return( $data , $file ) if wantarray ;
  return $data ;
}

#########
# REVAL #
#########

sub reval {
  if ( !$EVAL_VALUES_COMPARTMENT ) {
    $EVAL_VALUES_COMPARTMENT = Safe->new('Config::XMLPerl::EVAL') ;
    $EVAL_VALUES_COMPARTMENT->permit_only(@PERMIT_OPS) ;
  }
  return $EVAL_VALUES_COMPARTMENT->reval(@_) ;
}

###############
# CLEAN_CACHE #
###############

sub CLEAN_CACHE {
  %CACHE = () ;
  $CACHE_SLEEP = undef ;
}

#######
# END #
#######

sub END { &CLEAN_CACHE ;}

#######
# END #
#######

1;


__END__


=head1 NAME

Config::XMLPerl - Configuration files based in XML, where Perl data codes as XML values are enabled.

=head1 DESCRIPTION

This module enable the use of normal XML files as configuration files, but also
enable Perl data codes as definition of values.

The XML also don't need to be well formatted, soo you can write by hand a wild XML file and use it normally.

=head1 USAGE

  use Config::XMLPerl qw(config_load) ;
  
  my $config = config_load("conf.xml") ;
  
  ## or: my $config = new Config::XMLPerl("conf.xml") ;
  
  my $server = $config->{server} ;
  my $port = $config->{port} ;
  
  my $db_user = $config->{DB}{user} ;
  my $db_pass = $config->{DB}{pass} ;
  my $db_host = $config->{DB}{host} ;
  
  print $config->{text} ;
  
  __DATA__
  
  <config server="domain.foo" por="80">

    DB => { user => "foo" , pass => "123" , host => "db.domain.foo"}

    <text>
      this is
      a text
      content
    </text>

  </config>

=head1 METHODS

=head2 config_load ( FILE|DATA|FILEHANDLE )

Loads the specified file and returns a I<XML::Smart> object.

To see how to access a I<XML::Smart> object see: L<XML::Smart>

=over 4

=item FILE|DATA|FILEHANDLE

Can be a FILE path, DATA (SCALAR) or FILEHANDLE (GLOB).

=back

=head1 SYNTAX (XML + Perl)

The syntax of the configuration file basically is XML, but that accepts extra things.

=over 4

=item You don't need to add the XML header:

  <?xml version="1.0">

=item The tags accept any non space character, soo you can have tags like:

  <.willd/> <n*/>

=item You don't need to use quotes for the arguments:

  <tagx arg1=123 href=http:/www arg2="quoted">

=back

=head2 Perl

To use Perl data structure for the values you just set the values as in the content (B<one per line>):

  <perl_code_sample foo="123" bar="456">
    hash => { user => "foo" , pass => "123" , host => "db.domain.foo"}
    list => [qw(a b c d)]
    string => "some text\n with a new line"
    time => time()
  </perl_code_sample>

Note that the keys for the values (I<hash,list,string,time>) need to be a valid Perl word. Soo, need to match with:

  qr/^\w+[\w:\.]*$/s

The separator (=>) can be "=>", "=", "->" or ":":

  <separators>
    foo => 'like hash'
    foo -> 'like OO'
    foo: 123
    foo = 'equal'
  </separators>

B<** Note that a Perl code can't use more than one line, soo this syntax is wrong:>

  <error>
    invalid => {
               a => 1 ,
               a => 2 ,
               }
  </error>

=head1 EXPORTING TO WELL FORMATTED XML

To export a wild XML to a well formatted XML use:

  my $config = config_load(q`
  <config server="domain.foo" port=80>
    DB => { user => "foo" , pass => 123 , host => "db.domain.foo"}
  </config>
  `) ;

  ## Save to a file:
  $config->save("ok.xml") ;
  
  ## print the file:
  print $config->data() ;

Output:

  <?xml version="1.0" encoding="iso-8859-1" ?>
  <?meta name="GENERATOR" content="XML::Smart/1.5 Perl/5.006001 [MSWin32]" ?>
  <config server="domain.foo" port="80">
    <DB host="db.domain.foo" pass="123" user="foo"/>
  </config>

I<** See L<XML::Smart> for complete use of B<save()> and B<data>.>

=head1 Safe Compartment

To evaluate the Perl codes of the XML files, a L<Safe> compartment is used,
and only I<OP> that wont change the symbol-table or make CODE call will be enabled.

Soo, basically you are only enabled to create anonymous variables.

B<OPCODE list:>

  :base_mem

    null stub pushmark const defined undef

    preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec
    int hex oct abs pow multiply i_multiply divide i_divide
    modulo i_modulo add i_add subtract i_subtract

    left_shift right_shift bit_and bit_xor bit_or negate i_negate
    not complement

    lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp
    slt sgt sle sge seq sne scmp

    substr stringify length ord chr

    ucfirst lcfirst uc lc quotemeta trans chop schop chomp schomp

    match split

    list lslice reverse

    cond_expr flip flop andassign orassign and or xor

    lineseq scope enter leave setstate

    rv2cv

    leaveeval
  
  gvsv gv gelem

  padsv padav padhv padany

  refgen srefgen ref

  time
  sort
  pack unpack

=head1 NOTES

This module was first created for the XML config files of L<HPL>,
and was turned into a Perl Module to be published to the public independent of I<HPL>.

=head1 SEE ALSO

L<XML::Smart>, L<Safe>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


