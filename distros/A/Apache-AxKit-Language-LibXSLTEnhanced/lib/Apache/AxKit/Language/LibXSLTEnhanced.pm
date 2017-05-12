package Apache::AxKit::Language::LibXSLTEnhanced;

#use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::AxKit::Language::LibXSLTEnhanced ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

use strict;
use vars qw/@ISA $VERSION %DEPENDS/;
use XML::LibXSLT 1.30;
use XML::LibXML;
use Apache;
use Apache::Request;
use Apache::AxKit::Language;
use Apache::AxKit::Provider;
use Apache::AxKit::LibXMLSupport;

@ISA = 'Apache::AxKit::Language';

$VERSION = 1.0; # this fixes a CPAN.pm bug. Bah!

my %style_cache;

sub reset_depends {
    %DEPENDS = ();
}

sub add_depends {
    $DEPENDS{shift()}++;
}

sub get_depends {
    return keys %DEPENDS;
}

sub handler {
    my $class = shift;
    my ($r, $xml, $style, $last_in_chain) = @_;
    
    my ($xmlstring, $xml_doc);
    
    AxKit::Debug(7, "[LibXSLT] getting the XML");
    
    if (my $dom = $r->pnotes('dom_tree')) {
        $xml_doc = $dom;
        delete $r->pnotes()->{'dom_tree'};
    }
    else {
        $xmlstring = $r->pnotes('xml_string');
    }
    
    my $parser = XML::LibXML->new();
    $parser->expand_entities(1);
    local($XML::LibXML::match_cb, $XML::LibXML::open_cb,
          $XML::LibXML::read_cb, $XML::LibXML::close_cb);
    Apache::AxKit::LibXMLSupport->reset();
    local $Apache::AxKit::LibXMLSupport::provider_cb = 
        sub {
            my $r = shift;
            my $provider = Apache::AxKit::Provider->new_content_provider($r);
            add_depends($provider->key());
            return $provider;
        };

    if (!$xml_doc && !$xmlstring) {
        $xml_doc = $xml->get_dom();
    } 
    elsif ($xmlstring) {
        $xml_doc = $parser->parse_string($xmlstring, $r->uri());
    }

    $xml_doc->process_xinclude();
    
    AxKit::Debug(7, "[LibXSLT] parsing stylesheet");

    my $stylesheet;
    my $cache = $style_cache{$style->key()};
    if (ref($cache) eq 'HASH' && !$style->has_changed($cache->{mtime}) && ref($cache->{depends}) eq 'ARRAY') {
        AxKit::Debug(8, "[LibXSLT] checking if stylesheet is cached");
        my $changed = 0;
        DEPENDS:
        foreach my $depends (@{ $cache->{depends} }) {
            my $p = Apache::AxKit::Provider->new_style_provider($r, key => $depends);
            if ( $p->has_changed( $cache->{mtime} ) ) {
                $changed = 1;
                last DEPENDS;
            }
        }
        if (!$changed) {
            AxKit::Debug(7, "[LibXSLT] stylesheet cached");
            $stylesheet = $style_cache{$style->key()}{style};
        }
    }
    
    if (!$stylesheet || ref($stylesheet) ne 'XML::LibXSLT::Stylesheet') {
        reset_depends();
        my $style_uri = $style->apache_request->uri();
        AxKit::Debug(7, "[LibXSLT] parsing stylesheet $style_uri");
        my $style_doc = $style->get_dom();
        
        local($XML::LibXML::match_cb, $XML::LibXML::open_cb,
            $XML::LibXML::read_cb, $XML::LibXML::close_cb);
        Apache::AxKit::LibXMLSupport->reset();
        local $Apache::AxKit::LibXMLSupport::provider_cb = 
            sub {
                my $r = shift;
                my $provider = Apache::AxKit::Provider->new_style_provider($r);
                add_depends($provider->key());
                return $provider;
            };
    
        $stylesheet = XML::LibXSLT->parse_stylesheet($style_doc);
        
        foreach( $r->dir_config->get("LibXSLTFunctionsModule") ) {
            eval("require $_" );
        
            if( $@ ) {
                die "Could not load module.\n $@";
            }
        
            my $function_lib = $_->new();
        
            foreach( $function_lib->getFunctions() ) {
                XML::LibXSLT->register_function( $function_lib->getNamespace(), $_->[0], $_->[1] );
            }
        }

        unless ($r->dir_config('AxDisableXSLTStylesheetCache')) {
            $style_cache{$style->key()} = 
                { style => $stylesheet, mtime => time, depends => [ get_depends() ] };
        }
    }

    # get request form/querystring parameters
    my @params = fixup_params($class->get_params($r));

    AxKit::Debug(7, "[LibXSLT] performing transformation");

    my $results = $stylesheet->transform($xml_doc, @params);
    
    AxKit::Debug(7, "[LibXSLT] transformation finished, creating $results");
    
    if ($last_in_chain) {
        AxKit::Debug(8, "[LibXSLT] outputting to \$r");
        if ($XML::LibXSLT::VERSION >= 1.03) {
            my $encoding = $stylesheet->output_encoding;
            my $type = $stylesheet->media_type;
            $r->content_type("$type; charset=$encoding");
        }
        $stylesheet->output_fh($results, $r);
    }

    AxKit::Debug(7, "[LibXSLT] storing results in pnotes(dom_tree) ($r)");
    $r->pnotes('dom_tree', $results);
    
#         warn "LibXSLT returned $output \n";
#         print $stylesheet->output_string($results);
    return Apache::Constants::OK;

}

sub fixup_params {
    my @results;
    while (@_) {
        push @results, XML::LibXSLT::xpath_to_string(
                splice(@_, 0, 2)
                );
    }
    return @results;
}

1;








# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::AxKit::Language::LibXSLTEnhanced - AxKit extension to load perl callbacks for XSL

=head1 SYNOPSIS
  
  <Files *.zuml>
      AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLTEnhanced
      PerlAddVar LibXSLTFunctionsModule BestSolution::AddonFunctions
  </Files>

=head1 DESCRIPTION

This module is working completly like Language::LibXSLT but it support registering 
perl-functions which can be used in XSL-Stylesheets. To add a Perl-Callbacks you
have to use PerlAddVar as shown in synopsis. The module loaded has to inherit from
L<Apache::AxKit::Util::LibXSLTAddonFunction>

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Apache::AxKit::Language::LibXSLT>, L<AxKit>, L<Apache::AxKit::Util::LibXSLTAddonFunction>

=head1 AUTHOR

Tom Schindl, E<lt>tom.schindl@bestsolution.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tom Schindl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
