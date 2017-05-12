#
# This file is part of Dancer2-Plugin-Feed
#
# This software is copyright (c) 2016 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer2::Plugin::Feed;
$Dancer2::Plugin::Feed::VERSION = '1.160550';
use Dancer2::Plugin;
use XML::Feed;

#ABSTRACT: Easy to generate feed rss or atom for Dancer2 applications.

my $ct = {
    atom => 'application/atom+xml',
    rss  => 'application/rss+xml',
};

my @feed_properties =
  qw/format title base link tagline description author id language copyright self_link modified/;

my @entries_properties =
  qw/title base link content summary category tags author id issued modified enclosure/;

register create_feed => sub {
    my ($dsl, %params) = @_;

    my $format = _validate_format(\%params);

    if (lc $format eq 'atom') {
        _create_atom_feed($dsl, \%params);
    }
    elsif(lc $format eq 'rss') {
        _create_rss_feed($dsl, \%params);
    }
    else {
        die "Unknown format $format, use rss or atom\n";
    }
};

register create_atom_feed => sub {
    my ($dsl, %params) = plugin_args(@_);

    _create_atom_feed($dsl, \%params);
};

register create_rss_feed => sub {
    my ($dsl, %params) = plugin_args(@_);

    _create_rss_feed($dsl, \%params);
};

sub _validate_format {
    my( $params, $dsl ) = @_;
    my $format = delete $params->{format};

    if (!$format) {
        my $settings = plugin_setting;
        $format      = $settings->{format}
            or die "Feed format is missing\n";
    }

    if (! exists $ct->{$format}) {
        die "Unknown format $format, use rss or atom\n";
    }

    return $format;
}

sub _create_feed {
    my ($format, $params) = @_;

    my $entries = delete $params->{entries};

    my $feed     = XML::Feed->new($format);
    my $settings = plugin_setting;

    foreach (@feed_properties) {
        my $val = $params->{$_} || $settings->{$_};
        $feed->$_($val) if ($val);
    }

    foreach my $entry (@$entries) {
        my $e = XML::Feed::Entry->new($format);

        foreach (@entries_properties) {
            my $val = $entry->{$_};
            $e->$_($val) if $val
        }

        $feed->add_entry($e);
    }

    return $feed->as_xml;
}

sub _create_atom_feed {
    my ($dsl, $params) = @_;

    $dsl->content_type($ct->{atom});
    _create_feed('Atom', $params);
}

sub _create_rss_feed {
    my ($dsl, $params) = @_;

    $dsl->content_type($ct->{rss});
    _create_feed('RSS', $params);
}

register_plugin for_versions => [2];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Feed - Easy to generate feed rss or atom for Dancer2 applications.

=head1 VERSION

version 1.160550

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Feed;
    use Try::Tiny;

    get '/feed/:format' => sub {
        my $feed;
        try {
            $feed = create_feed(
                format  => params->{format},
                title   => 'my great feed',
                entries => [ map { title => "entry $_" }, 1 .. 10 ],
            );
        }
        catch {
            my ( $exception ) = @_;

            if ( $exception->does('FeedInvalidFormat') ) {
                return $exception->message;
            }
            elsif ( $exception->does('FeedNoFormat') ) {
                return $exception->message;
            }
            else {
                $exception->rethrow;
            }
        };

        return $feed;
    };

    dance;

=head1 DESCRIPTION

Provides an easy way to generate RSS or Atom feed. This module relies on L<XML::Feed>. Please, consult the documentation of L<XML::Feed> and L<XML::Feed::Entry>.

=head1 CONFIGURATION

 plugins:
   Feed:
     title: my great feed
     format: Atom

=head1 FUNCTIONS

=head2 create_feed

This function returns a XML feed. All parameters can be define in the configuration

AcceptEd parameters are:

=over 4

=item format (required)

The B<Content-Type> header will be set to the appropriate value

=item entries

An arrayref containing a list of entries. Each item will be transformed to an L<XML::Feed::Entry> object. Each entry is an hashref. Some common attributes for these hashrefs are C<title>, C<link>, C<summary>, C<content>, C<author>, C<issued> and C<modified>. Check L<XML::Feed::Entry> for more details.

=item title

=item base

=item link

=item tagline

=item description

=item author

=item language

=item copyright

=item self_link

=item modified

=back

=head2 create_atom_feed

This method call B<create_feed> by setting the format to Atom.

=head2 create_rss_feed

This method call B<create_feed> by setting the format to RSS.

=head1 CONTRIBUTING

This module is developed on Github at:

L<http://github.com/hobbestigrou/Dancer2-Plugin-Feed>

Feel free to fork the repo and submit pull requests

=head1 ACKNOWLEDGEMENTS

Alexis Sukrieh and Franck Cuny

=head1 BUGS

Please report any bugs or feature requests in github.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Feed

=head1 SEE ALSO

L<Dancer2>
L<XML::Feed>
L<XML::Feed::Entry>
L<Dancer::Plugin::Feed>

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
