package API::ParallelsWPB::Requests;

use strict;
use warnings;

use Carp;


use constant {
    DEFAULT_LOCALE_CODE       => 'en_US',
    DEFAULT_TEMPLATE_CODE     => 'generic',
    DEFAULT_CREATE_SITE_STATE => 'trial',
    DEFAULT_SESSIONLIFETIME   => '1800',
};

# ABSTRACT: processing of API requests

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:IMAGO'; # AUTHORITY


sub get_version {
    my ( $self ) = @_;

    return $self->f_request( [qw/ system version /], { req_type => 'get' } );
}


sub create_site {
    my ( $self, %param ) = @_;

    $param{state}                ||= DEFAULT_CREATE_SITE_STATE;
    $param{publicationSettings}  ||= {};
    $param{ownerInfo}            ||= {};
    $param{isPromoFooterVisible} ||= '';

    my $post_array = [ {
        state                => $param{state},
        publicationSettings  => $param{publicationSettings},
        ownerInfo            => $param{ownerInfo},
        isPromoFooterVisible => $param{isPromoFooterVisible}
    } ];

    my $res = $self->f_request(
        ['sites'],
        {
            req_type  => 'post',
            post_data => $post_array,
        }
    );

    my $uuid = $res->response;
    if ( $uuid ) {
        $self->{uuid} = $uuid;
    }
    else {
        carp "parameter uuid not found";
    }

    return $res;
}


sub gen_token {
    my ( $self, %param ) = @_;

    $param{localeCode}      ||= DEFAULT_LOCALE_CODE;
    $param{sessionLifeTime} ||= DEFAULT_SESSIONLIFETIME;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request(
        [ 'sites', $uuid, 'token' ],
        {
            req_type  => 'post',
            post_data => [
                {
                    localeCode => $param{localeCode},
                    sessionLifeTime => $param{sessionLifeTime},
                } ],
        }
    );
}


sub deploy {
    my ( $self, %param ) = @_;

    $param{localeCode}   ||= $self->DEFAULT_LOCALE_CODE;
    $param{templateCode} ||= $self->DEFAULT_TEMPLATE_CODE;
    my $siteuuid = $self->_get_uuid( %param );

    my @post_data = map { $param{$_} } qw/templateCode localeCode title/;

    return $self->f_request(
        [ 'sites', $siteuuid, 'deploy' ],
        {
            req_type  => 'post',
            post_data => \@post_data
        }
    );
}



sub get_site_info {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid ], { req_type => 'get' } );
}



sub get_sites_info {
    my ( $self ) = @_;

    return $self->f_request( [qw/ sites /], { req_type => 'get' } );
}


sub change_site_properties {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );
    return $self->f_request(
        [ 'sites', $uuid ],
        {
            req_type  => 'put',
            post_data => [\%param]
        }
    );
}



sub publish {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );
    return $self->f_request(
        [ 'sites', $uuid, 'publish' ],
        {
            req_type  => 'post',
        }
    );
}



sub delete_site {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid ], { req_type => 'delete' } );
}



sub get_promo_footer {
    my ( $self ) = @_;

    return $self->f_request( [qw/ system promo-footer /],
        { req_type => 'get' } );
}


sub get_site_custom_variable {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid, 'custom-properties' ], { req_type => 'get' } );
}


sub set_site_custom_variable {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    delete $param{uuid} if ( exists $param{uuid} );
    return $self->f_request( [ 'sites', $uuid, 'custom-properties' ],
        {
            req_type  => 'put',
            post_data => [ \%param ],
        }
    );
}


sub get_sites_custom_variables {
    my ( $self ) = @_;

    return $self->f_request( [qw/ system custom-properties /],
        { req_type => 'get' } );
}


sub set_sites_custom_variables {
    my ( $self, %param ) = @_;

    return $self->f_request( [ qw/ system custom-properties / ],
        {
            req_type  => 'put',
            post_data => [ \%param ],
        }
    );
}


sub set_custom_trial_messages {
    my ( $self, @param ) = @_;

    return $self->f_request( [ qw/ system trial-mode messages / ],
        {
            req_type  => 'put',
            post_data => [ \@param ]
        }
    );
}


sub get_custom_trial_messages {
    my ( $self ) = @_;

    return $self->f_request( [qw/ system trial-mode messages /],
        { req_type => 'get' } );
}


sub change_promo_footer {
    my ( $self, %param ) = @_;

    confess "Required parameter message!" unless ( $param{message} );

    return $self->f_request( [ qw/ system promo-footer / ],
        {
           req_type  => 'put',
           post_data => [ $param{message} ],
        }
    );
}


sub set_site_promo_footer_visible {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid ], {
            req_type  => 'put',
            post_data => [ { isPromoFooterVisible => 'true' } ],
        }
    );
}


sub set_site_promo_footer_invisible {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid ], {
            req_type  => 'put',
            post_data => [ { isPromoFooterVisible => 'false' } ],
        }
    );
}



sub set_limits {
    my ( $self, %param ) = @_;

    my $uuid = $self->_get_uuid( %param );

    return $self->f_request( [ 'sites', $uuid, 'limits' ], {
            req_type  => 'put',
            post_data => [ \%param ],
        }
    );
}


sub configure_buy_and_publish_dialog {
    my ( $self, $params ) = @_;

    return $self->f_request(['system', 'trial-mode', 'messages'], {req_type => 'put', post_data => [ $params ]});

}

sub _get_uuid {
    my ( $self, %param ) = @_;

    my $uuid = $param{uuid} ? $param{uuid} : $self->{uuid};
    confess "Required parameter uuid!" unless ( $uuid );

    return $uuid;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::ParallelsWPB::Requests - processing of API requests

=head1 VERSION

version 0.03

=head1 METHODS

=head2 B<get_version($self)>

Getting the current version of the Parallels Web Presence Builder instance on the defined server.

=head2 B<create_site($self, %param)>

Creating a site.

%param:

state

    trial | suspended | regular

    This parameter is optional.
    It specifies whether the site is in the trial mode, suspended or active (regular value). Sites in the trial mode can be edited, but cannot be published to a hosting account.

publicationSettings

    {
        "targetUrl" => "ftp://username:password@ftp.example.com/path",
        "webSiteUrl" => "http://example.com",
        "fallbackIp" => "192.168.1.3"
    }

    This parameter is optional.

ownerInfo

    {
        "personalName" => "John Doe",
        "companyName"  => "My Company LTD",
        "phone"        => "+1-954-555-555",
        "email"        => "john@example.com",
        "address"      => "New",
        "city"         => "New York",
        "state"        => "New York",
        "zip"          => "10292",
        "country"      => "United states"
    }

    This parameter is optional.

isPromoFooterVisible

    1 | 0

    This parameter is optional.
    It specifies whether a text box containing an advertisement should be shown in a website footer (a section that appears at the bottom of every page on a site).
    To learn more about how to set the content to be shown in the promotional footer,
    see the section L<Configuring the Promotional Footer|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/71977.htm>.

L<Creating a Site|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=69689.htm>

=head2 B<gen_token($self, %param)>

Generating a Security Token for Accessing a Site

%param:

uuid

    Site UUID. This parameter is mandatory.

localeCode

    This parameter is optional.

    It specifies the language that should be set for the user interface when the user (site owner) logs in to the editor.

    The following languages are supported:

        en_US - American English.
        en_GB - British English.
        de_DE - German.
        es_ES - Spanish.
        fr_FR - French
        it_IT - Italian.
        ja_JP - Japanese.
        nl_NL - Dutch.
        pl_PL - Polish.
        pt_BR - Brazilian Portuguese
        ru_RU - Russian.
        zh_CN - simplified Chinese.
        zh_TW - traditional Chinese.

    If no locale is defined, en_US will be used.

sessionLifeTime

    This parameter is optional. It specifies the period of inactivity for a user's session in the editor. When this period elapses,
    the security token expires and the user needs to log in again. 1800 seconds by default.

L<Generating a Security Token for Accessing a Site|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=69691.htm>

=head2 B<deploy($self, %param)>

Creates site based on a specified topic.

    my $response =
      $client->deploy( localeCode => 'en_US', templateCode => 'music_blog' );

%param:

uuid

    Site UUID. This parameter is mandatory.

localeCode

    Locale code. The default value is en_US.

templateCode

    Internal topic identification code. This parameter is optional. Default value is 'generic'.

title

    Website name. This parameter is optional. Specifies what should be shown as the website name in the browser's title bar.

L<Creating a Site Based on a Website Topic|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=72111.htm>

=head2 B<get_site_info($self, %param)>

Retrieving information about a specific site.

%param:

uuid

    Site UUID. This parameter is mandatory.

L<Retrieving Information About a Specific Site|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=69690.htm>

=head2 B<get_sites_info($self)>

Retrieving information about all sites.

No parameters are required.

L<Retrieving Information About All Sites|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71285.htm>

=head2 B<change_site_properties($self, %param)>

Changes site properties.

%param:

state

    trial | suspended | regular

    This parameter is optional. It specifies whether the site is in trial mode, suspended or active (regular value). Sites in trial mode can be edited, but cannot be published to a hosting account.

publicationSettings

    This parameter is optional. It specifies where to publish the site over FTP and what account credentials to use:

ownerInfo

    This parameter is optional. It specifies the contact information of the site owner.

isPromoFooterVisible

    1 | 0

    This parameter is optional. It specifies whether a text box with an advertisement should be shown in the website footer.

L<Changing Site Properties and Settings|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=69692.htm>

=head2 B<publish($self,%param)>

Publish a site.

%param:

uuid

    Site UUID.

L<Publishing a Website|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=72112.htm>

=head2 B<delete_site($self, %param)>

Deleting a site.

%param:

uuid

    Site UUID.

L<Deleting a Site|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=69669.htm>

=head2 B<get_promo_footer( $self )>

Retrieving the current content of the promotional footer.

L<Retrieving the Current Content of the Promotional Footer|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71979_1.htm>

=head2 B<get_site_custom_variable($self, %param)>

Retrieving a List of Custom Variables for a Website.

%param:

uuid

    Site UUID.

L<Configuring the Trial Mode|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71623.htm>

L<Setting Trial Mode Messages|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71727.htm>

=head2 B<set_site_custom_variable($self, %param)>

Setting a Custom Variable for a Website

%param:

    uuid
    variable1 => value1
    variable2 => value2
    ...
    variableN => valueN

L<Configuring the Trial Mode|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71623.htm>

L<Setting Trial Mode Messages|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71727.htm>

=head2 B<get_sites_custom_variables($self)>

Retrieving Custom Variables Defined for All Websites

L<Configuring the Trial Mode|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71623.htm>

L<Setting Trial Mode Messages|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71727.htm>

=head2 B<set_sites_custom_variables($self, %param)>

Setting Custom Variables for All Websites

%param:

    variable1 => value1
    variable2 => value2
    ...
    variableN => valueN

L<Configuring the Trial Mode|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71623.htm>

L<Setting Trial Mode Messages|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71727.htm>

=head2 B<set_custom_trial_messages($self, @param)>

Setting Custom Messages for the Trial Mode

    my $response = $api->set_custom_trial_messages(
        {
            localeCode  => 'en_US',
            messages    => {
                defaultPersonalName => '{message1_en}',
                editorTopMessageTrialSite => '{message2_en}',
                initialMailSubject => '{message3_en}',
                initialMailHtml => '{message4_en}',
                trialSiteSignUpPublishTitle => '{message5_en}',
                trialSiteSignUpPublishMsg => '{message6_en}'
            }
        },
        {
            localeCode  => 'de_DE',
            messages    => {
                defaultPersonalName => '{message1_de}',
                editorTopMessageTrialSite => '{message2_de}',
                initialMailSubject => '{message3_de}',
                initialMailHtml => '{message4_de}',
                trialSiteSignUpPublishTitle => '{message5_de}',
                trialSiteSignUpPublishMsg => '{message6_de}'
            }
        },
    );

=head2 B<get_custom_trial_messages($self)>

Retrieving Custom Messages for the Trial Mode

=head2 B<change_promo_footer($self, %param)>

Changing the Default Content of the Promotional Footer

%param:

    message

=head2 B<set_site_promo_footer_visible($self, %param)>

Showing the Promotional Footer on Websites

%param:

    uuid

=head2 B<set_site_promo_footer_invisible($self, %param)>

Removing the Promotional Footer from Websites

%param:

    uuid

=head2 B<set_limits>

Set limitations for single site

%param:

uuid

    Site UUID.

The next list contains parameters/modules, that can be limited. Value for parameter must be an integer, that means maximum number of elements, that can be added on site. Value -1 means unlimited elements count
for all modules/pages except eshop module. It can accept only positive numbers.

maxPagesNumber

    Number of pages on a site.

video

    Embedded Video module.

imagegallery

    Image Gallery module.

blog

    Blog module.

eshop

    Online Store and Shopping Cart modules.

commenting

    Commenting module.

contact

    Contact Form module.

sharethis

    Social Sharing module.

advertisement

    Advertisement module.

map

    Map module.

search

    Search module.

navigation

    Navigation module.

breadcrumbs

    Breadcrumbs module.

siteLogo

    Site Logo module.

script

    Script module.

slider

    Image Slider module.

L<Restricting Resources by Means of the API|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71986.htm>

=head2 B<configure_buy_and_publish_dialog>

Configuration for Buy & Publish dialog box in constructor.

$params:

    [
        {
            "localeCode" => "de_DE",

            "messages" => {

                "upsellDialogTitle" => $title,
                "upsellDialogMsg"   => $html

            }
        },
        {
            "localeCode" => "ru_RU",

            "messages" => {

                "upsellDialogTitle" => $title,
                "upsellDialogMsg"   => $html

            }
        }
    ]

L<Configuring the Buy and Publish Dialog Window|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide/index.htm?fileName=71987.htm>

=head1 NAME

API::ParallelsWPB::Requests

=head1 SEE ALSO

L<Parallels Presence Builder Guide|http://download1.parallels.com/WPB/Doc/11.5/en-US/online/presence-builder-standalone-installation-administration-guide>

L<API::ParallelsWPB>

L<API::ParallelsWPB::Response>

=head1 AUTHORS

=over 4

=item *

Alexander Ruzhnikov <a.ruzhnikov@reg.ru>

=item *

Polina Shubina <shubina@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
