package App::Perlambda::CLI::Create;

use strict;
use warnings;
use utf8;
use AWS::CLIWrapper;
use File::Spec;

use App::Perlambda::Util qw(parse_options get_current_perl_version);

sub run {
    my ($self, @args) = @_;

    my $profile;
    my $region;
    my $aws_account;
    my $iam_role;
    my $perl_version = get_current_perl_version();
    my $layer_version;
    my $func_name;
    my $handler;
    my $zip;

    parse_options(
        \@args,
        'profile=s'           => \$profile,
        'region=s'            => \$region,
        'aws_account=s'       => \$aws_account,
        'iam_role=s'          => \$iam_role,
        'perl_version=s'      => \$perl_version,
        'layer_version=s'     => \$layer_version,
        'func_name=s'         => \$func_name,
        'handler=s'           => \$handler,
        'zip=s'               => \$zip,
    );

    for my $v (qw/region aws_account iam_role func_name handler zip layer_version/) {
        unless (eval "\$$v") { ## no critic
            die "mandatory parameter --$v is missing. please see the doc: `perlambda help create`\n";
        }
    }

    $perl_version =~ s/[.]/_/;
    my $layer_aws_account = '652718333417';

    my $lambda_opt = {
        'function-name' => $func_name,
        'zip-file'      => 'fileb://' . File::Spec->rel2abs($zip),
        handler         => $handler,
        runtime         => 'provided',
        role            => "arn:aws:iam::$aws_account:role/$iam_role",
        layers          => "arn:aws:lambda:${region}:${layer_aws_account}:layer:perl-${perl_version}-layer:${layer_version}",
    };

    my %aws_opt = (
        region => $region,
    );
    $aws_opt{profile} = $profile if $profile;
    my $aws = AWS::CLIWrapper->new(%aws_opt);

    my $res = $aws->lambda("create-function" => $lambda_opt);
    unless ($res) {
        die sprintf("%s:%s\n", $AWS::CLIWrapper::Error->{Code}, $AWS::CLIWrapper::Error->{Message});
    }
}

1;

__END__

=encoding utf8

=head1 NAME

App::Perlambda::CLI::Create - Create a Lambda function on AWS with perl layer

=head1 SYNOPSIS

    $ perlambda create --region=<AWS region> \
                       --aws_account=<your AWS account> \
                       --iam_role=<your IAM role> \
                       --layer_version=<version of the layer> \
                       --func_name=<your func name> \
                       --handler=<your handler name> \
                       --zip=<func zip file>

=head1 DESCRIPTION

This command creates a new Lambda function on AWS with perl layer.

This command uses L<AWS::CLIWrapper> so it requires C<aws> command is on your PATH. For more information, please see: L<https://aws.amazon.com/cli/>

=head1 COMMANDLINE OPTIONS

=head2 C<--region> (B<Mandatory>)

AWS region for deployment environment.

=head2 C<--aws_account> (B<Mandatory>)

AWS account ID.

=head2 C<--iam_role> (B<Mandatory>)

The Amazon Resource Name (ARN) of the function's execution role.

=head2 C<--layer_version> (B<Mandatory>)

The version of Lambda Perl layer.

=head2 C<--func_name> (B<Mandatory>)

The name of the Lambda function.

=head2 C<--handler> (B<Mandatory>)

The name of the method within your code that Lambda calls to execute your function.

=head2 C<--zip> (B<Mandatory>)

The path to the zip file of the code you are uploading.

=head2 C<--profile> (B<Optional>)

B<Default>: your system default

Your AWS profile.

=head2 C<--perl_version> (B<Optional>)

B<Default>: version of running perl

The version of perl runtime. You have to specify this parameter as C<5_xx> (e.g. C<5_26> and C<5.28>).

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

