package App::Perlambda::CLI::Update;

use strict;
use warnings;
use utf8;
use AWS::CLIWrapper;
use File::Spec;

use App::Perlambda::Util qw(parse_options);

sub run {
    my ($self, @args) = @_;

    my $profile;
    my $region;
    parse_options(
        \@args,
        'profile=s' => \$profile,
        'region=s'  => \$region,
    );

    if (scalar(@args) < 2) {
        die "invalid argument has come. please see the doc: `perlambda help update`\n";
    }

    my $func_name = $args[0];
    my $zip = File::Spec->rel2abs($args[1]);

    my %aws_opt;
    $aws_opt{region} = $region if $region;
    $aws_opt{profile} = $profile if $profile;

    my $aws = AWS::CLIWrapper->new(%aws_opt);

    my $res = $aws->lambda("update-function-code" => {
        'function-name' => $func_name,
        'zip-file'      => "fileb://$zip",
    });
    unless ($res) {
        die sprintf("%s:%s\n", $AWS::CLIWrapper::Error->{Code}, $AWS::CLIWrapper::Error->{Message});
    }
}

1;

__END__

=encoding utf8

=head1 NAME

App::Perlambda::CLI::Update - Update the Lambda function code.

=head1 SYNOPSIS

    $ perlambda update [--profile=<your AWS profile>] [--region=<AWS region of Lambda function>] <func name> <zip file path>

=head1 DESCRIPTION

This command updates the Lambda function code by zip archive.

This command uses L<AWS::CLIWrapper> so it requires C<aws> command is on your PATH. For more information, please see: L<https://aws.amazon.com/cli/>

=head1 COMMANDLINE OPTIONS

=head2 C<--profile> (B<Optional>)

B<Default>: your system default

Your AWS profile.

=head2 C<--region> (B<Optional>)

B<Default>: your system default

AWS region of your Lambda function.

=head1 REQUIREMENTS

=over 4

=item * Perl 5.26 or later

=item * L<awscli|https://aws.amazon.com/cli/>

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

