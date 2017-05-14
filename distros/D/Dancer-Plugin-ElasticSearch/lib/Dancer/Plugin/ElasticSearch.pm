package Dancer::Plugin::ElasticSearch;

# ABSTRACT: An ElasticSearch wrapper for Dancer

use Dancer qw(:syntax);
use Dancer::Plugin;

use ElasticSearch;

### TODO : connection pooling
my $Connection;

register elsearch => sub {
    return $Connection || _create_connection();
};

sub _create_connection {
    my $settings = plugin_setting;
    my $cxn      = ElasticSearch->new(%$settings)
        or die q(Error creating ElasticSearch connection);
    return $Connection = $cxn;
}

register_plugin;

true;

__END__

=head1 TAKE NOTE

This module is ALPHA and subject to change. Use at your own risk.

=head1 NAME

Dancer::Plugin::ElasticSearch - ElasticSearch wrapper for Dancer

=head1 SYNOPSIS

    use Dancer::Plugin::ElasticSearch;

        $data = elsearch->get(
            index => 'twitter',
            type  => 'tweet',
            id    => 1
        );

=head1 DESCRIPTION

Dancer::Plugin::ElasticSearch allows easy ES use with the elsearch keyword.

=head1 METHODS

=head2 elsearch

Returns an ES connection object.

=head1 CONFIG

Make sure to appropriately configure the plugin in your config.yml
    
    plugins:
        ElasticSearch:
            servers		    : 127.0.0.1:9200
            transport		: http
            max_requests	: 10_000
            trace_calls	    : 1
            no_refresh		: 0

=head1 SEE ALSO
 
L<Dancer>, L<ElasticSearch>, perl(1)
 
=head1 AUTHOR
 
Job van Achterberg <jkva@cpan.org>
 
=head1 LICENSE
 
Copyright (C) 2011 Job van Achterberg <jkva@cpan.org>
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
See http://www.perl.com/perl/misc/Artistic.html
 
=cut
