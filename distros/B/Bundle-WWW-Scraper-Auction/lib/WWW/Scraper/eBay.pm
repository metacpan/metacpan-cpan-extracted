
package WWW::Scraper::eBay;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.01 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(2.27 generic_option addURL trimTags trimLFs));

my $scraperRequest = 
   { 
      'type' => 'FORM'
     ,'formNameOrNumber' => 'search_form'
     ,'submitButton' => undef

     # This is the basic URL on which to build the query.
     ,'url' => 'http://pages.ebay.com/search/items/basicsearch.html'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'query'
     ,'nativeDefaults' => {
                            'query' => undef
                          }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
        [ 'HTML', 
            [ 
               [ 'COUNT', '([,0-9]+)</b>\s+items found\s+for']
              ,[ 'BODY', '</form>', undef,
                  [  
                     #[ 'NEXT', 2, \&findNextForm ] # it used to be a form . . .
                     [ 'NEXT', 1, 'Next >' ]
                    ,[ 'BODY', '<!-- eBayCacheStart -->', '<!-- eBayCacheEnd -->',
                       [ 
                           [ 'TABLE', '#0' ]
                          ,[ 'HIT*' , 'Auction',
                             [ 
#try again!                                [ 'TRYUNTIL', 2, 'url', [
                                [ 'TABLE', 
                                   [  
                                      [ 'TR',
                                         [
                                            # <img height="15" width="64" border="0" alt="Pic" src="http://pics.ebay.com/aw/pics/lst/_p__64x15.gif">
                                            #[ 'TD',[ [ 'REGEX', '<img\s+.*?src=([^ >)', 'thumbNailUrl'] ] ]
                                            [ 'TD' ] # The thumbnail url is in there somewhere!
                                           ,[ 'TD',[ [ 'A', 'url', 'title' ] ] ]
                                           ,[ 'TD', 'price', \&parsePrice ]
                                           ,[ 'TD', 'bids', \&trimLFs ]
                                           ,[ 'TD', 'endsPDT', \&trimLFs ]
                                            # this regex never matches; just lets us declare fields.
                                           #,[ 'REGEX', 'neverMatch', 'isNew', 'itemNumber' ] #, 'isBillpoint']
                                         ]
                                      ]
                                   ]
                                ] 
#try again!                                ] ]
                             ] 
                           ] 
                          ,[ 'TABLE', '#2' ]
                          ,[ 'HIT*' , 'Auction',
                             [ 
#try again!                                [ 'TRYUNTIL', 2, 'url', [
                                [ 'TABLE', 
                                   [  
                                      [ 'TR',
                                         [
                                            # <img height="15" width="64" border="0" alt="Pic" src="http://pics.ebay.com/aw/pics/lst/_p__64x15.gif">
                                            #[ 'TD',[ [ 'REGEX', '<img\s+.*?src=([^ >)', 'thumbNailUrl'] ] ]
                                            [ 'TD' ] # The thumbnail url is in there somewhere!
                                           ,[ 'TD',[ [ 'A', 'url', 'title' ] ] ]
                                           ,[ 'TD', 'price', \&parsePrice ]
                                           ,[ 'TD', 'bids', \&trimLFs ]
                                           ,[ 'TD', 'endsPDT', \&trimLFs ]
                                            # this regex never matches; just lets us declare fields.
                                           #,[ 'REGEX', 'neverMatch', 'isNew', 'itemNumber' ] #, 'isBillpoint']
                                         ]
                                      ]
                                   ]
                                ] 
#try again!                                ] ]
                             ] 
                           ] 
                          #,[ 'BOGUS', -2 ] # eBay's last 2 hits are bogus ("return to top", etc.).
                       ] 
                     ]
                  ]
               ]
            ]
        ];



sub testParameters {
    return {
                 'SKIP' => '' 
                ,'TODO' => "Implement 'TRYUNTIL' Scraper frame option - helps for skipping 'hits' that aren't actually hits."
                ,'testNativeQuery' => 'turntable'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 25
                ,'expectedBogusPage' => 0
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::SetScraperFrame($scraperFrame); return $scraperFrame }
sub scraperDetail{ undef }



my $defaultScraperForm_url = ['http://pages.ebay.com/search/items/search.html', 0, 'query', undef];
sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $scraperRequest->{'url'} = $_->{'scraperBaseURL'};  # new form
            $$defaultScraperForm_url[0] = $_->{'scraperBaseURL'}; # old form
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}


# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
sub findNextForm {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
        # Reconstruct the form that contains the NEXT data.
        my @forms = HTML::Form->parse("<form $frm>$sub_content</form>", $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() eq 'Next' ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return '';
}


# eBay's title sometimes includes other things, such as "new" link and "billpoint" link
#<td valign=top width=52%><font size=3><a href="http://cgi.ebay.com/ws/eBayISAPI.dll?ViewItem&item=1383008995">UNITED AUDIO TURNTABLE DUAL 1209 MODEL</a></font>
#<BR><img height=1 width=200 border=0 alt="" src="http://pics.ebay.com/aw/pics/s.gif"></td>
sub parseItemTitle {
   my ($self, $hit, $dat) = @_;
   my $next_content = $dat;
   my ($sub_content, $frm);
   my ($isNew, $isBillpoint) = (0,0);
   while ( ($sub_content, $frm) = $self->getMarkedText('A', \$next_content) ) {
      last unless $sub_content;
      $isNew       |= ($sub_content =~ m{alt="New!"})?1:0;
      $isBillpoint |= ($sub_content =~ m{alt="eBay Online Payments by Billpoint"})?1:0;
      last unless $sub_content =~ m{<img}i;
   }
   $hit->plug_elem('title', $sub_content);
   $hit->plug_elem('isNew', $isNew);
#   $hit->plug_elem('isBillpoint', $isBillpoint); # need to match Billpoint *after* matching title.
   my $url = $frm;
   $url =~ s{a\s+href=(['"])(.*)$1}{$2};
   $url =~ m{item=(\d+)$};
   $hit->plug_elem('itemNumber', $1);
   return $url;
}

# eBay's price sometimes contains multiple values ("Buy it Now")
sub parsePrice {
    my ($self, $hit, $dat) = @_;
    for my $price ( split /<BR>/, $dat) {
        $price = $self->trimLFs($hit, $price);
        next unless $price;
        $hit->plug_elem('price', $price);
    }
    return undef; # we already plugged the values into the $hit.
}
1;

__END__

=pod

=head1 NAME

WWW::Scraper::eBay - Scrapes www.eBay.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('eBay');


=head1 DESCRIPTION

This class is an eBay extension of WWW::Scraper.
It handles making and interpreting eBay searches
F<http://www.eBay.com>.

=head1 OPTIONS

=over 8

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


=head1 AUTHOR

C<WWW::Scraper::eBay> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#####################################################################

