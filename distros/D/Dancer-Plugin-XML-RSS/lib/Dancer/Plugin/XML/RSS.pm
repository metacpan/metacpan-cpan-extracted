package Dancer::Plugin::XML::RSS;

use Dancer ':syntax';
use Dancer::Plugin;

use XML::RSS;

our $VERSION = '0.01';

register 'rss' => sub {
    my $option   = shift; # 'new' force creation of new obj
    my $settings = plugin_setting || {};

    debug( $settings );
    
    # need to lookup format for plugin setting and see if this will map to
    # values correct in xml::rss object
    var xml_rss_obj => (
        ! vars->{xml_rss_obj} || ( defined $option && $option =~ /new/i ) ? 
            XML::RSS->new( %{ $settings } ) : vars->{xml_rss_obj} ); 

    return vars->{xml_rss_obj};
};

register 'rss_output' => sub {
    content_type('text/xml'); # or application/xml+rss?
    return vars->{xml_rss_obj}->as_string;
};

register_plugin;

=head1 NAME

Dancer::Plugin::XML::RSS - Dancer plugin for using XML::RSS to parse or create RSS feeds

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Allows access to XML::RSS object from inside of your Dancer application and
default configuration of XML::RSS using the standard Dancer configuration file.

    package MyDancerApp;

    use Dancer 'syntax';
    use Dancer::Plugin::XML::RSS;

    # parse rss file and output
    get '/show_news' => {
      rss->parsefile( settings( 'news_feed' ) );

      # grab entries for template
      my @stories;
      my $display_max = settings('news_feed_display') || 5;

      for ( my $i = 0; $i <= $display_max; $i++ ) {
        next unless exists rss->{items}->[$i] 
          and ref rss->{items};

        push @stories, $item;
      }

      template 'news', { stories => \@stories };
    };

    get '/our_feed' => {
        rss->channel( 
            title => 'My Special Site',
            link  => 'mysite.example.org',
            description => 'A generic example for docs',
        );

        rss->add_item( 
        );

        rss_output;
    };

=head1 DESCRIPTION

Provides a simple way to parse RSS files by using C<XML::RSS>. It will hold onto currently
parsed feed or keyword 'rss' will return object instance for application use.

Using the 'rss_output' command it will first create correct content type and then 
serialize object into RSS XML for use in route. 

=head1 CONFIGURATION 

XML:RSS configuration parameters will be taken from your C<Dancer> application config file. They should be specified as:

    plugins:
       'XML::RSS':
          output:  '0.9'  # output as rss v0.9

See C<XML::RSS> for more detail on configuration options.


=head1 SUBROUTINES/METHODS

=head2 rss('new')

Creates and returns XML::RSS object. It will be setup with any XML::RSS options from configuration file.

After first call to rss existing XML::RSS object will be called to force a new object pass 
'new' to C<rss>

=over 

=item 'new' - optional string to force creation of new rss object

=back

=cut

=head2 rss_output

Converts XML::RSS object into xml with correct content type and body. Use for returning inside of route.

=head1 AUTHOR

Lee Carmichael, C<< <lcarmich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-xml-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-XML-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::XML::RSS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-XML-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-XML-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-XML-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-XML-RSS/>

=back

=head1 TODO

=over 4

=item * Add configuration of output header with config file

=item * Use configuration file to setup details of channel for rss output

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lee Carmichael.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

C<Dancer>, C<XML::RSS>, C<Dancer::Plugin>, C<Dancer::Plugin::Feed>

=cut

1; # End of Dancer::Plugin::XML::RSS
