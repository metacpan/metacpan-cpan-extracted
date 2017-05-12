package App::Beeminder::Hook;
use Dancer ':syntax';
use JSON::Any;
use autodie;
use Data::Dumper;

# ABSTRACT: Integrate Github and Beeminder

our $VERSION = '0.1';

# inspired by https://github.com/solgenomics/sgn-devtools/blob/master/git/github_post_receive

# This will eventually use WWW::Beeminder when that is ready, but for now, curl saves the day
any '/hook' => sub {
    my $p = param('payload');

    unless ($p) {
        my $response = JSON::Any->encode( { success => 0 } );
        return $response;
    }

    $p = JSON::Any->new->decode( $p );

    debug(Dumper($p));

    my $repo_name    = $p->{repository}{name};
    my $organization = $p->{repository}{organization};
    my $num_commits  = @{$p->{commits}};
    my $day_of_month = (localtime(time))[3];

    my $cmd=<<CMD;
curl -d 'origin=%s&datapoints_text=%s %s "%s"&sendmail=0' %s/%s/goals/%s/datapoints/create_all
CMD

    $cmd = sprintf($cmd, config->{beeminder_username},
        $day_of_month,
        $num_commits,
        "$organization/$repo_name", # optional comment
        config->{beeminder_api_url},
        config->{beeminder_username},
        config->{beeminder_goal},
    );
    debug "Running: $cmd";
    system $cmd;

    my $response = JSON::Any->encode( { success => 1 } );
};

get '/' => sub {
    'This is App::Beeminder::Hook';
};

true;

__END__
=pod

=head1 NAME

App::Beeminder::Hook - Integrate Github and Beeminder

=head1 VERSION

version 0.003

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leto Labs LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

