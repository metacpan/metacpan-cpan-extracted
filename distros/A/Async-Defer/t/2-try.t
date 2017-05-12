use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 17;


my ($d);
my ($result, @result);


# try
# catch
# - require even number of params, min 2
# - only catch
# - only finally
# - first matched catch/finally used
# - both catch and finally, in any order, but catch executes first
# - both catch and finally, in any order, but catch executes first and re-throw
# - auto re-throw if no matched catch (with and without finally)

$d = Async::Defer->new();
throws_ok { $d->catch()         } qr/require at least 2 params/;
throws_ok { $d->catch(1)        } qr/require at least 2 params/;
lives_ok  { $d->catch(1,2)      } '2 params';
throws_ok { $d->catch(1,2,3)    } qr/require even number of params/;
lives_ok  { $d->catch(1,2,3,4)  } '4 params';

$d = Async::Defer->new();
$d->try();
$d->do(sub{
    my ($d) = @_;
    if ($d->{err}) {
        $d->throw($d->{err});
    } else {
        $d->done();
    }
});
$d->catch(
    qr/^fatal:/ => sub {
        my ($d, $err) = @_;
        $result = $err;
        $d->done();
    }
);
($d->{err}, $result) = (); $d->run();
is $result, undef,          'no error - no catch';
($d->{err}, $result) = ('fatal:oops'); $d->run();
is $result, 'fatal:oops',   'fatal error - catched';
($d->{err}, $result) = ('warn:some');
throws_ok { $d->run(); } qr/uncatched exception/;

$d = Async::Defer->new();
$d->try();
$d->try();
$d->do(sub{
    my ($d) = @_;
    if ($d->{err}) {
        $d->throw($d->{err});
    } else {
        $d->done('ok');
    }
});
$d->catch(
    FINALLY => sub {
        my ($d, $err) = @_;
        $result = $err;
        $d->done();
    }
);
$d->catch(
    qr// => sub {},
);
($d->{err}, $result) = (); $d->run();
is $result, 'ok',          'no error - finally got "ok"';
($d->{err}, $result) = ('fatal:oops'); $d->run();
is $result, 'fatal:oops',   'error - finally got "fatal:oops"';

$d = Async::Defer->new();
$d->try();
$d->do(sub{
    my ($d) = @_;
    $d->throw($d->{err});
});
$d->catch(
    qr/io:/ => sub {
        my ($d, $err) = @_;
        push @result, 'io:';
        $d->done();
    },
    FINALLY => sub {
        my ($d, $err) = @_;
        push @result, 'f1';
        $d->done();
    },
    qr/warn:/ => sub {
        my ($d, $err) = @_;
        push @result, 'warn:';
        $d->done();
    },
    FINALLY => sub {
        my ($d, $err) = @_;
        push @result, 'f2';
        $d->done();
    },
    qr// => sub {
        my ($d, $err) = @_;
        push @result, '//';
        $d->done();
    },
    qr/fatal:oops/ => sub {
        my ($d, $err) = @_;
        push @result, 'fatal:oops';
        $d->done();
    },
);
($d->{err}, @result) = ('io:eof'); $d->run();
is_deeply \@result, ['io:','f1'], 'first matched catch/finally used';
($d->{err}, @result) = ('warn:timeout'); $d->run();
is_deeply \@result, ['warn:','f1'], '…';
($d->{err}, @result) = ('fatal:bug'); $d->run();
is_deeply \@result, ['//','f1'], '…';
($d->{err}, @result) = ('fatal:oops'); $d->run();
is_deeply \@result, ['//','f1'], '…';

$d = Async::Defer->new();
$d->try();
    $d->try();
    $d->do(sub{
        my ($d) = @_;
        $d->throw($d->{err});
    });
    $d->catch(
        qr/fatal:/ => sub {
            my ($d, $err) = @_;
            push @result, 'fatal';
            $d->throw('BUG');
        },
        FINALLY => sub {
            my ($d, $err) = @_;
            push @result, 'fin';
            $d->done();
        },
    );
$d->catch(
    qr/BUG/ => sub{
        my ($d, $err) = @_;
        push @result, 'bug';
        $d->done();
    },
);
($d->{err}, @result) = ('fatal:oops'); $d->run();
is_deeply \@result, ['fatal','fin','bug'], 'both catch and finally, catch re-throw';
($d->{err}, @result) = ('BUG:here'); $d->run();
is_deeply \@result, ['fin','bug'], 'auto re-throw if no matched catch, with finally';

$d = Async::Defer->new();
$d->try();
    $d->try();
    $d->do(sub{
        my ($d) = @_;
        $d->throw($d->{err});
    });
    $d->catch(
        qr/fatal:/ => sub {
            my ($d, $err) = @_;
            push @result, 'fatal';
            $d->throw('BUG');
        },
    );
$d->catch(
    qr/BUG/ => sub{
        my ($d, $err) = @_;
        push @result, 'bug';
        $d->done();
    },
);
($d->{err}, @result) = ('BUG:here'); $d->run();
is_deeply \@result, ['bug'], 'auto re-throw if no matched catch, without finally';


