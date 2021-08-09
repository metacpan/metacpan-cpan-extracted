use strict;
use warnings;

use Test::Requires {
    'Email::Sender' => '0',
};

use Test::Fatal;
use Test::More 0.88;
use Test::Warnings qw( warnings );

use Courriel::Builder;

## no critic (Variables::RequireLocalizedPunctuationVars)
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

my @warnings = warnings {
    require Email::Sender::Simple;
    Email::Sender::Simple->import(qw( sendmail ));
};
if ( $] >= 5.018 && $] < 5.020 ) {
    if ( @warnings == 1 ) {
        like(
            shift @warnings,
            qr/Module::Pluggable will be removed from the Perl core distribution in the next major release/,
            'Got warning about Module::Pluggable',
        );
    }
}
is_deeply( \@warnings, [], 'no warnings loading Email::Sender::Simple' );

{
    Email::Sender::Simple->default_transport->clear_deliveries;

    my $email = build_email(
        subject('test send'),
        from('joe@example.com'),
        to('jane@example.com'),
        plain_body('This is the body.'),
    );

    sendmail($email);

    my @sent = Email::Sender::Simple->default_transport->deliveries;

    is(
        scalar @sent, 1,
        'sent one email'
    );

    is_deeply(
        $sent[0]->{envelope}, {
            from => 'joe@example.com',
            to   => ['jane@example.com'],
        },
        'got the right envelope for sent email'
    );

    is(
        $sent[0]->{email}->as_string,
        $email->as_string,
        'sent email had the right body'
    );
}

{
    Email::Sender::Simple->default_transport->clear_deliveries;

    my $email = build_email(
        subject('test send'),
        from('joe@example.com'),
        to('jane@example.com'),
        plain_body('This is the body.'),
        attach( content => 'Plain text content' ),
    );

    is(
        exception { sendmail($email) },
        undef,
        'no exception sending email with attachment via Email::Sender::Simple'
    );

    my @sent = Email::Sender::Simple->default_transport->deliveries;

    is(
        scalar @sent, 1,
        'sent one email'
    );

    is_deeply(
        $sent[0]->{envelope}, {
            from => 'joe@example.com',
            to   => ['jane@example.com'],
        },
        'got the right envelope for sent email'
    );

    is(
        $sent[0]->{email}->as_string,
        $email->as_string,
        'sent email had the right body'
    );
}

done_testing();
