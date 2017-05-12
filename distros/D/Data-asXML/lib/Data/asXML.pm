package Data::asXML;

=encoding utf-8

=head1 NAME

Data::asXML - convert data structures to/from XML

=head1 SYNOPSIS

    use Data::asXML;
    my $dxml = Data::asXML->new();
    my $dom = $dxml->encode({
        'some' => 'value',
        'in'   => [ qw(a data structure) ],
    });

    my $data = $dxml->decode(q{
        <HASH>
            <KEY name="some"><VALUE>value</VALUE></KEY>
            <KEY name="in">
                <ARRAY>
                    <VALUE>a</VALUE>
                    <VALUE>data</VALUE>
                    <VALUE>structure</VALUE>
                </ARRAY>
            </KEY>
        </HASH>
    });

    my (%hash1, %hash2);
    $hash1{other}=\%hash2;
    $hash2{other}=\%hash1;
    print Data::asXML->new->encode([1, \%hash1, \%hash2])->toString;
    
    <ARRAY>
        <VALUE>1</VALUE>
    	<HASH>
		    <KEY name="other">
			    <HASH>
				    <KEY name="other">
					    <HASH href="../../../../*[2]"/>
    				</KEY>
	    		</HASH>
		    </KEY>
    	</HASH>
    	<HASH href="*[2]/*[1]/*[1]"/>
    </ARRAY>

For more examples see F<t/01_Data-asXML.t>.

=head1 WARNING

experimental, use at your own risk :-)

=head1 DESCRIPTION

There are couple of modules mapping XML to data structures. (L<XML::Compile>,
L<XML::TreePP>, L<XML::Simple>, ...) but they aim at making data structures
adapt to XML structure. This one defines couple of simple XML tags to represent
data structures. It makes the serialization to and from XML possible.

For the moment it is an experiment. I plan to use it for passing data
structures as DOM to XSLT for transformations, so that I can match them
with XPATH similar way how I access them in Perl.

    /HASH/KEY[@name="key"]/VALUE
    /HASH/KEY[@name="key2"]/ARRAY/*[3]/VALUE
    /ARRAY/*[1]/VALUE
    /ARRAY/*[2]/HASH/KEY[@name="key3"]/VALUE

If you are looking for a module to serialize your data, without requirement
to do so in XML, you should probably better have a look at L<JSON::XS>
or L<Storable>.

=cut

use warnings;
use strict;

use utf8;
use 5.010;
use feature 'state';

use Carp 'croak';
use XML::LibXML 'XML_ELEMENT_NODE';
use Scalar::Util 'blessed';
use URI::Escape qw(uri_escape uri_unescape);
use Test::Deep::NoTest 'eq_deeply';
use XML::Char;
use MIME::Base64 'decode_base64';

our $VERSION = '0.07';

use base 'Class::Accessor::Fast';

=head1 PROPERTIES

=over 4

=item pretty

(default 1 - true) will insert text nodes to the XML to make the output indented.

=item safe_mode

(default undef - false)

in case of C<encode()> perform the xml string decoding back and will compare
the two data structures to be sure the data can be reconstructed back without
errors.

in case of a C<decode()> it will decode to data then encode to xml string and from
xml string decode back to data. this two data values are then compared.

Both compares is done using L<Test::Deep::NoTest>::eq_deeply.

=item namespace

(default undef - false)

adds xml:ns attribute to the root element. if C<namespace> is set to 1
the xml:ns will be L<http://search.cpan.org/perldoc?Data::asXML> otherwise
it will be the value of C<namespace>.

=back

=cut

__PACKAGE__->mk_accessors(qw{
    pretty
    safe_mode
    namespace
    namespace_prefix
});

=head1 METHODS

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new({
        'pretty' => 1,
        @_
    });
    
    return $self;
}

sub _xml {
    my($self) = @_;
    if(not exists $self->{'_xml'}) {
        my $xml = XML::LibXML::Document->new("1.0", "UTF-8");
        $self->{'_xml'} = $xml;
    }
    return $self->{'_xml'};
}


sub _indent {
    my $self   = shift;
    my $where  = shift;
    my $indent = shift;
    
    $where->addChild( $self->_xml->createTextNode( "\n".("\t" x $indent) ) )
        if $self->pretty;
}

sub _createElement {
    my $self = shift;
    my $name = shift;
    my $namespace        = $self->namespace;
    my $namespace_prefix = $self->namespace_prefix;

    $name = join(':',$namespace_prefix,$name)
        if $namespace_prefix;

    if ($namespace) {
        return $self->_xml->createElementNS( $namespace, $name );
    }
    else {
        return $self->_xml->createElement($name);
    }
}

=head2 encode($what)

From structure C<$what> generates L<XML::LibXML::Document> DOM. Call
C<< ->toString >> to get XML string. For more actions see L<XML::LibXML>.

=cut

sub encode {
    my $self  = shift;
    my $what  = shift;
    my $pos   = shift || 1;
    my $where;
    
    my $safe_mode = $self->safe_mode;
    $self->safe_mode(0);
    my $add_namespace = $self->namespace || 0;
    $add_namespace = "http://search.cpan.org/perldoc?Data::asXML"
        if $add_namespace eq '1';
    $self->namespace(0);
    $self->namespace($add_namespace)
        if $add_namespace;
    
    state $indent = 0;

    if (not $self->{'_cur_xpath_steps'}) {
        $self->{'_href_mapping'}    = {};
        $self->{'_cur_xpath_steps'} = [];
    }
    
    # create DOM for hash element
    if (ref($what) eq 'HASH') {
            $where = $self->_createElement('HASH');
            $indent++;
            push @{$self->{'_cur_xpath_steps'}}, $pos;
            # already encoded reference
            if (exists $self->{'_href_mapping'}->{$what}) {
                $where->setAttribute(
                    'href' =>
                    $self->_make_relative_xpath(
                        [ split(',', $self->{'_href_mapping'}->{$what}) ],
                        $self->{'_cur_xpath_steps'}
                    )
                );
                $indent--;
                pop @{$self->{'_cur_xpath_steps'}};
                return $where;
            }
            $self->{'_href_mapping'}->{$what} = $self->_xpath_steps_string();
            
            my $key_pos = 0;
            foreach my $key (sort keys %{$what}) {
                my $value = $what->{$key};
                $key_pos++;
                $self->_indent($where, $indent);
                $indent++;

                my $el = $self->_createElement('KEY');
                push @{$self->{'_cur_xpath_steps'}}, $key_pos;
                $self->_indent($el, $indent);
                $el->setAttribute('name', $key);
                $el->addChild($self->encode($value));

                $indent--;
                $self->_indent($el, $indent);
                pop @{$self->{'_cur_xpath_steps'}};

                $where->addChild($el);
            }
            
            $indent--;
            $self->_indent($where, $indent);
            pop @{$self->{'_cur_xpath_steps'}};
        }
    # create DOM for array element
    elsif (ref($what) eq 'ARRAY') {
            $where = $self->_createElement('ARRAY');
            $indent++;
            push @{$self->{'_cur_xpath_steps'}}, $pos;
            # already encoded reference
            if (exists $self->{'_href_mapping'}->{$what}) {
                $where->setAttribute(
                    'href' =>
                    $self->_make_relative_xpath(
                        [ split(',', $self->{'_href_mapping'}->{$what}) ],
                        $self->{'_cur_xpath_steps'}
                    )
                );
                $indent--;
                pop @{$self->{'_cur_xpath_steps'}};
                return $where;
            }
            $self->{'_href_mapping'}->{$what.''} = $self->_xpath_steps_string();
            
            my $array_pos = 0;
            foreach my $value (@{$what}) {
                $array_pos++;
                $self->_indent($where, $indent);
                $where->addChild($self->encode($value, $array_pos));
            }
            
            $indent--;
            $self->_indent($where, $indent);
            pop @{$self->{'_cur_xpath_steps'}};
        }
        # create element for pure reference
    elsif (ref($what) eq 'REF') {
            $where = $self->_createElement('REF');
            $indent++;
            push @{$self->{'_cur_xpath_steps'}}, $pos;
            # already encoded reference
            if (exists $self->{'_href_mapping'}->{$what}) {
                $where->setAttribute(
                    'href' =>
                    $self->_make_relative_xpath(
                        [ split(',', $self->{'_href_mapping'}->{$what}) ],
                        $self->{'_cur_xpath_steps'}
                    )
                );
                $indent--;
                pop @{$self->{'_cur_xpath_steps'}};
                return $where;
            }
            $self->{'_href_mapping'}->{$what.''} = $self->_xpath_steps_string();
            
            $self->_indent($where, $indent);
            $where->addChild($self->encode($$what));
            
            $indent--;
            $self->_indent($where, $indent);
            pop @{$self->{'_cur_xpath_steps'}};
        }
        # scalar reference
    elsif (ref($what) eq 'SCALAR') {
            push @{$self->{'_cur_xpath_steps'}}, $pos;
            # already encoded reference
            if (exists $self->{'_href_mapping'}->{$what}) {
                $where = $self->_createElement('VALUE');
                $where->setAttribute(
                    'href' =>
                    $self->_make_relative_xpath(
                        [ split(',', $self->{'_href_mapping'}->{$what}) ],
                        $self->{'_cur_xpath_steps'}
                    )
                );
                pop @{$self->{'_cur_xpath_steps'}};
                return $where;
            }
            $self->{'_href_mapping'}->{$what.''} = $self->_xpath_steps_string();

            $where = $self->encode($$what);
            $where->setAttribute('subtype' => 'ref');

            pop @{$self->{'_cur_xpath_steps'}};
        }
    # create text node
    elsif (ref($what) eq '') {
            $where = $self->_createElement('VALUE');
            if (defined $what) {
                # uri escape if it contains invalid XML characters
                if (not XML::Char->valid($what)) {
                    $what = join q(), map {
                        (/[[:^print:]]/ or q(%) eq $_) ? uri_escape $_ : $_
                    } split //, $what;
                    $where->setAttribute('type' => 'uriEscape');
                }
                $where->addChild( $self->_xml->createTextNode( $what ) );
            }
            else {
                # no better way to distinguish between empty string and undef - see http://rt.cpan.org/Public/Bug/Display.html?id=51442
                $where->setAttribute('type' => 'undef');
            }
                
        }
        #
    else {
            die 'unknown reference - '.$what;
    }

    # cleanup at the end
    if ($indent == 0) {
        $self->{'_href_mapping'}    = {};
        $self->{'_cur_xpath_steps'} = [];
    }

    # in safe_mode decode back the xml string and compare the data structures
    if ($safe_mode) {
        my $xml_string = $where->toString;
        my $what_decoded = eval { $self->decode($xml_string) };
        
        die 'encoding failed '.$@.' of '.eval('use Data::Dumper; Dumper([$what, $xml_string, $what_decoded])').' failed'
            if not eq_deeply($what, $what_decoded);
        
        # set back the safe mode after all was encoded
        $self->safe_mode($safe_mode);
    }

    return $where;
}

sub _xpath_steps_string {
    my $self       = shift;
    my $path_array = shift || $self->{'_cur_xpath_steps'};
    return join(',',@{$path_array});
}

sub _make_relative_xpath {
    my $self      = shift;
    my $orig_path = shift;
    my $cur_path  = shift;
    
    # find how many elements (from beginning) the paths are sharing
    my $common_root_index = 0;
    while (
            ($common_root_index < @$orig_path)
            and ($orig_path->[$common_root_index] == $cur_path->[$common_root_index])
    ) {
        $common_root_index++;
    }
    
    # add '..' to move up the element hierarchy until the common element
    my @rel_path = ();
    my $i = $common_root_index+1;
    while ($i < scalar @$cur_path) {
        push @rel_path, '..';
        $i++;
    }
    
    # add the original element path steps
    $i = $common_root_index;
    while ($i < scalar @$orig_path) {
        push @rel_path, $orig_path->[$i];
        $i++;
    }
    
    # in case of self referencing the element index is needed
    if ($i == $common_root_index) {
        push @rel_path, '..', $orig_path->[-1];
    }
    
    # return relative xpath
    return join('/', map { $_ eq '..' ? $_ : '*['.$_.']' } @rel_path);
}

=head2 decode($xmlstring)

Takes C<$xmlstring> and converts to data structure.

=cut

sub decode {
    my $self = shift;
    my $xml  = shift;
    my $pos   = shift || 1;

    # in safe_mode "encode+decode" the decoded data for comparing
    if ($self->safe_mode) {
        $self->safe_mode(0);
        my $data           = $self->decode($xml, $pos);
        my $data_redecoded = eval { $self->decode(
            $self->encode($data)->toString,
            $pos,
        )};
        die 'redecoding failed "'.$@.'" of '.eval('use Data::Dumper; Dumper([$xml, $data, $data_redecoded])').' failed'
            if not eq_deeply($data, $data_redecoded);
        $self->safe_mode(1);
        return $data;
    }

    if (not $self->{'_cur_xpath_steps'}) {
        local $self->{'_href_mapping'}    = {};
        local $self->{'_cur_xpath_steps'} = [];
    }

    my $value;
    
    if (not blessed $xml) {
        my $parser       = XML::LibXML->new();
        my $doc          = $parser->parse_string($xml);
        my $root_element = $doc->documentElement();
        
        return $self->decode($root_element);
    }
    
    if ($xml->nodeName eq 'HASH') {
            if (my $xpath_path = $xml->getAttribute('href')) {
                my $href_key = $self->_href_key($xpath_path);
                return $self->{'_href_mapping'}->{$href_key} || die 'invalid reference - '.$href_key.' ('.$xml->toString.')';
            }
            
            push @{$self->{'_cur_xpath_steps'}}, $pos;
            
            my %data;
            $self->{'_href_mapping'}->{$self->_xpath_steps_string()} = \%data;
            my @keys =
                grep { $_->nodeName eq 'KEY' }
                grep { $_->nodeType eq XML_ELEMENT_NODE }
                $xml->childNodes()
            ;
            my $key_pos = 1;
            foreach my $key (@keys) {
                push @{$self->{'_cur_xpath_steps'}}, $key_pos;
                my $key_name  = $key->getAttribute('name');
                my $key_value = $self->decode(grep { $_->nodeType eq XML_ELEMENT_NODE } $key->childNodes());     # is always only one
                $data{$key_name} = $key_value;
                pop @{$self->{'_cur_xpath_steps'}};
                $key_pos++;
            }
            pop @{$self->{'_cur_xpath_steps'}};
            return \%data;
        }
    elsif ($xml->nodeName eq 'ARRAY') {
            if (my $xpath_path = $xml->getAttribute('href')) {
                my $href_key = $self->_href_key($xpath_path);
                
                return $self->{'_href_mapping'}->{$href_key} || die 'invalid reference - '.$href_key.' ('.$xml->toString.')';
            }

            push @{$self->{'_cur_xpath_steps'}}, $pos;

            my @data;
            $self->{'_href_mapping'}->{$self->_xpath_steps_string()} = \@data;
            
            my $array_element_pos = 1;
            @data = map { $self->decode($_, $array_element_pos++) } grep { $_->nodeType eq XML_ELEMENT_NODE } $xml->childNodes();
            pop @{$self->{'_cur_xpath_steps'}};
            return \@data;
        }
    elsif ($xml->nodeName eq 'REF') {
            if (my $xpath_path = $xml->getAttribute('href')) {
                my $href_key = $self->_href_key($xpath_path);
                return $self->{'_href_mapping'}->{$href_key} || die 'invalid reference - '.$href_key.' ('.$xml->toString.')';
            }

            push @{$self->{'_cur_xpath_steps'}}, $pos;

            my $data;
            $self->{'_href_mapping'}->{$self->_xpath_steps_string()} = \$data;
            
            ($data) = map { $self->decode($_) } grep { $_->nodeType eq XML_ELEMENT_NODE } $xml->childNodes();

            pop @{$self->{'_cur_xpath_steps'}};
            return \$data;
        }
    elsif ($xml->nodeName eq 'VALUE') {
            if (my $xpath_path = $xml->getAttribute('href')) {
                my $href_key = $self->_href_key($xpath_path);                
                return $self->{'_href_mapping'}->{$href_key} || die 'invalid reference - '.$href_key.' ('.$xml->toString.')';
            }

            push @{$self->{'_cur_xpath_steps'}}, $pos;
            my $value;
            $self->{'_href_mapping'}->{$self->_xpath_steps_string()} = \$value;
            pop @{$self->{'_cur_xpath_steps'}};
            
            my $type = $xml->getAttribute('type') // '';
            my $subtype = $xml->getAttribute('subtype') // '';
            if ($type eq 'undef')
                { $value = undef; }
            elsif ($type eq 'base64')
                { $value = decode_base64($xml->textContent) }    # left for backwards compatibility, will be removed one day...
            elsif ($type eq 'uriEscape')
                { $value = uri_unescape $xml->textContent; }
            else
                { $value = $xml->textContent }
            return \$value
                if ($subtype eq 'ref');
            return $value;
        }
    else {
        die 'invalid (unknown) element "'.$xml->toString.'"'
    }
    
}

sub _href_key {
    my $self               = shift;
    my $xpath_steps_string = shift;
    
    my @path        = @{$self->{'_cur_xpath_steps'}};
    my @xpath_steps =
        map { $_ =~ m/^\*\[(\d+)\]$/xms ? $1 : $_ }
        split('/', $xpath_steps_string)
    ;
    
    my $i = 0;
    while ($i < @xpath_steps) {
        if ($xpath_steps[$i] eq '..') {
            pop(@path);
        }
        else {
            push(@path, $xpath_steps[$i]);
        }
        $i++;
    }
    return $self->_xpath_steps_string(\@path)
}

1;


__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the Sys::Path by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯
    Emmanuel Rodriguez

=head1 TODO

    * int, float encoding ? (string enough?)
    * XSD
    * anyone else has an idea?
    * what to do with blessed? do the same as JSON::XS does?

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-asxml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-asXML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::asXML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-asXML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-asXML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-asXML>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-asXML/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::asXML
