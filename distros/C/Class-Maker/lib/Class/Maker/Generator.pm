
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Class::Maker::Generator;

our $VERSION = "0.06";

use 5.006; use strict; use warnings;

use XML::LibXSLT;

use XML::LibXML;

our $parser = XML::LibXML->new();

our $xslt = XML::LibXSLT->new();

Class::Maker::class
{
    public =>
    {
        string => [qw( source type lang stylesheet )],
    },

    private =>
    {
	string => [qw( repository basedir ) ],

        bool => [qw( generated )],
    },
};

sub _preinit : method
{
    my $this = shift;


    $this->type = 'FILE';
    
    $this->lang = 'perl';

    $this->_basedir = 'main.xsl';
}

sub _postinit : method
{
    my $this = shift;
}

sub output : method
{
    my $this = shift;


    $this->_repository = sprintf "%s/stylesheets/%s/", $this->dir, $this->lang;
 
    $this->stylesheet = $this->_repository.$this->_basedir;
    
    die sprintf( "%s does not exists. Are you sure that lang '%s' is supported ?", $this->stylesheet, $this->lang ) unless -e $this->stylesheet;

    # xslt translation

    my $stylesheet = $xslt->parse_stylesheet( $parser->parse_file( $this->stylesheet ) );

    my $type = uc $this->type;

    my $result;

    if( $type eq 'FILE' )
    {
	$result = $stylesheet->transform( $parser->parse_file( $this->source ) );
    }
    elsif( $type eq 'SCALAR' )
    {
	$result = $stylesheet->transform( $parser->parse_string( $this->source ) ) or die;
    }
    else
    {
	Carp::croak 'only FILE|SCALAR are allowed for type';
    }

    return $this->translate( $stylesheet->output_string($result) );

#return $result->toString();
}

sub translate : method
{
    my $this = shift;

    my $str = shift;


    $str =~ s/\r/\n\r/g;

return $str;
}

sub dir : method
{
    my $this = shift;


    use File::Basename qw(dirname);

    # Caution: brute force Win32 path translation.
    #          Will fail on unix with backlash espaced spaces etc.

    ( my $filename = __FILE__ ) =~ s/\\/\//g;

    return dirname( $filename  ).'/Generator';
}

sub whereami : method
{
    my $this = shift;

    use FindBin;
    
return "$FindBin::Bin";
}

1;

__END__

sabcmd perlClass.xsl Employee.xml 

