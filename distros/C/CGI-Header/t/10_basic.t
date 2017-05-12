use strict;
use warnings;
use CGI::Header;
use Test::More tests => 11; 
use Test::Exception;
use Test::Output;

subtest 'normalization' => sub {
    my $header = CGI::Header->new;

    my %data = (
        '-Content_Type'  => 'type',
        '-Cookie'        => 'cookies',
        #'-Set_Cookie'    => 'cookies',
        #'-Window_Target' => 'target',
    );

    while ( my ($input, $expected) = each %data ) {
        is $header->_normalize($input), $expected;
    }
};

subtest 'CGI::Header#new' => sub {
    my $header = CGI::Header->new;

    isa_ok $header, 'CGI::Header';
    isa_ok $header->header, 'HASH';
    isa_ok $header->query, 'CGI';

    throws_ok {
        CGI::Header->new(
            header => {
                -Type        => 'text/plain',
                Content_Type => 'text/html',
            }
        )
    } qr{^Property 'type' already exists};
};

subtest 'header fields' => sub {
    my $header = CGI::Header->new( header => { foo => 'bar' } );
    is $header->set( 'Foo' => 'bar' ), 'bar';
    is $header->get('Foo'), 'bar';
    ok $header->exists('Foo');
    is $header->delete('Foo'), 'bar';
};

subtest '#get' => sub {
    my $header = CGI::Header->new(
        header => {
            foo => 'bar',
            bar => 'baz',
        },
    );

    is $header->get('Foo'), 'bar';

    is $header->get('Foo', 'Bar'), 'baz',
        'get last property in scalar context';

    is_deeply(
        [ $header->get('Foo', 'Bar') ],
        [ 'bar', 'baz' ],
        'get multiple props. at once'
    );
};

subtest '#set' => sub {
    my $header = CGI::Header->new;

    throws_ok { $header->set('Foo') } qr{^Odd number of arguments passed},
        'exception with odd number arguments';

    is $header->set( Foo => 'bar' ), 'bar',
        'set return single new value in scalar context';

    is_deeply(
        [ $header->set( oink => 'blah', xxy => 'flop' ) ],
        [ 'blah', 'flop' ],
        'set returns newly set values in order of keys provided'
    );
    
    is_deeply $header->header, {
        foo  => 'bar',
        oink => 'blah',
        xxy  => 'flop',
    };
};

subtest '#delete' => sub {
    my $header = CGI::Header->new(
        header => {
            foo  => 'bar',
            oink => 'blah',
            xxy  => 'flop',
        },
    );

    is $header->delete('foo'), 'bar', 'delete returns deleted value';

    is_deeply(
        [ $header->delete('oink', 'xxy') ],
        [ 'blah', 'flop' ],
        'delete returns all deleted values in list context'
    );

    is_deeply $header->header, {};
};

subtest 'header props.' => sub {
    my $header = CGI::Header->new;

    is $header->attachment('genome.jpg'), $header;
    is $header->attachment, 'genome.jpg';

    is $header->charset('utf-8'), $header;
    is $header->charset, 'utf-8';

    is $header->cookies('ID=123456; path=/'), $header;
    is $header->cookies, 'ID=123456; path=/';

    is $header->expires('+3d'), $header;
    is $header->expires, '+3d';

    #is $header->location('http://somewhere.else/in/movie/land'), $header;
    #is $header->location, 'http://somewhere.else/in/movie/land';

    is $header->nph(1), $header;
    ok $header->nph;

    is $header->p3p('CAO DSP LAW CURa'), $header;
    is $header->p3p, 'CAO DSP LAW CURa';

    is $header->status('304 Not Modified'), $header;
    is $header->status, '304 Not Modified';

    is $header->target('ResultsWindow'), $header;
    is $header->target, 'ResultsWindow';

    is $header->type('text/plain'), $header;
    is $header->type, 'text/plain';

    is_deeply $header->header, {
        attachment => 'genome.jpg',
        charset    => 'utf-8',
        cookies    => 'ID=123456; path=/',
        expires    => '+3d',
        #location   => 'http://somewhere.else/in/movie/land',
        nph        => '1',
        p3p        => 'CAO DSP LAW CURa',
        status     => '304 Not Modified',
        target     => 'ResultsWindow',
        type       => 'text/plain',
    };
};

subtest 'CGI::Header#redirect' => sub {
    plan skip_all => 'obsolete';
    my $header = CGI::Header->new;
    is $header->redirect('http://somewhere.else/in/movie/land'), $header;
    is $header->location, 'http://somewhere.else/in/movie/land';
    is $header->status, '302 Found';
};

subtest 'CGI::Header#clear' => sub {
    my $header = { type => 'text/html', charset => 'utf-8' };
    my $h = CGI::Header->new( header => $header );
    is $h->clear, $h, 'should return current object itself';
    ok $h->header == $header;
    is_deeply $h->header, {}, 'should be empty';
};

subtest 'CGI::Header#finalize' => sub {
    my $header = CGI::Header->new;
    stdout_like { $header->type('text/plain')->finalize }
        qr{^Content-Type: text/plain; charset=ISO-8859-1};
};

subtest 'CGI::Header#clone' => sub {
    my $original = CGI::Header->new( header => { type => 'text/plain' } );
    my $clone = $original->clone;
    is_deeply $original->header, $clone->header;
    ok $original->header != $clone->header;
};
