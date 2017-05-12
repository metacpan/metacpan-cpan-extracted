#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;
use Data::YADV;

describe 'Data::YADV' => sub {
    my @errors;
    my $error_handler = sub {
        push @errors, [@_];
    };
    my @opts = (error_handler => $error_handler);

    before each => sub {
        @errors = ();
    };

    describe 'check_defined' => sub {
        it "should pass with correct data" => sub {
            Data::YADV->new({key => 'ok'}, @opts)->check('check_defined');
            ok !@errors;
        };

        it "should fail on undefined element" => sub {
            Data::YADV->new({key => undef}, @opts)->check('check_defined');
            is @errors, 1;
            my ($path, $message) = @{pop @errors};

            is $path,    '$structure->{key}';
            is $message, 'element not defined';
        };

        it "should fail on non existence element" => sub {
            Data::YADV->new({}, @opts)->check('check_defined');
            is @errors, 1;
            my ($path, $message) = @{pop @errors};

            is $path,    '$structure->{key}';
            is $message, 'element not found';
        };

        it "should accept structures" => sub {
            Data::YADV->new({key => 'ok'}, @opts)->check('check_structure');
            ok !@errors;
        };

        it "should accept structures and fail if it is missed" => sub {
            Data::YADV->new({}, @opts)->check('check_structure');
            is @errors, 1;
            my ($path, $message) = @{pop @errors};

            is $path,    '$structure->{key}';
            is $message, 'element not found';
        };
    };

    describe "check_value" => sub {
        it "should call proper callback" => sub {
            Data::YADV->new({result => 'secret'}, @opts)
              ->check('check_value');

            is @errors, 1;
            my ($path, $message) = @{pop @errors};
            is $path,    '$structure->{result}';
            is $message, 'secret';
        };
    };

    describe "check_each" => sub {
        it "should call callback on each array element" => sub {
            Data::YADV->new([[qw(value1 value2)]], @opts)
              ->check('check_each');

            is @errors, 2;
            my ($path, $message) = @{shift @errors};
            is $path,    '$structure->[0]->[0]';
            is $message, '0 - value1';

            ($path, $message) = @{shift @errors};
            is $path,    '$structure->[0]->[1]';
            is $message, '1 - value2';
        };

        it "should call callback on each hash element" => sub {
            Data::YADV->new([{key1 => 'value1', key2 => 'value2'}], @opts)
              ->check('check_each');

            is @errors, 2;
            @errors = sort {$a->[0] cmp $b->[0]} @errors;

            my ($path, $message) = @{shift @errors};
            is $path,    '$structure->[0]->{key1}';
            is $message, 'key1 - value1';

            ($path, $message) = @{shift @errors};
            is $path,    '$structure->[0]->{key2}';
            is $message, 'key2 - value2';
        };

        it "should use schema to check elements" => sub {
            Data::YADV->new([{result => 'value1'}, {result => 'value2'}],
                @opts)->check('check_each_schema');

            is @errors, 2;
            my ($path, $message) = @{shift @errors};
            is $path,    '$structure->[0]->{result}';
            is $message, 'value1';
        };

        it "should fail on not iterable" => sub {
            Data::YADV->new(['scalar'], @opts)->check('check_each');

            is @errors, 1;
            my ($path, $message) = @{pop @errors};
            is $path,    '$structure->[0]';
            is $message, 'scalar is not iterable';
        };
    };

    describe "check" => sub {
        it "should check schema" => sub {
            Data::YADV->new([{key => 'ok'}, {result => 'another secret'}],
                @opts)->check('check');

            is @errors, 1;
            my ($path, $message) = @{pop @errors};

            is $path,    '$structure->[1]->{result}';
            is $message, 'another secret';
        };
    };
};

runtests unless caller;

{

    package Schema::CheckDefined;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check_defined('{key}');
    }
};

{

    package Schema::CheckStructure;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check_defined($self->structure, '{key}');
    }
};

{

    package Schema::CheckValue;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check_value(
            '{result}' => sub {
                my ($self, $value) = @_;

                $self->error($value);
            }
        );
    }
}

{

    package Schema::CheckEach;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check_each(
            '[0]' => sub {
                my ($self, $element, $index) = @_;

                $self->error("$index - $element");
            }
        );
    }
}

{

    package Schema::CheckEachSchema;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check_each('check_value');
    }
}

{

    package Schema::Check;
    use base 'Data::YADV::Checker';

    sub verify {
        my $self = shift;

        $self->check('[0]' => 'check_defined');
        $self->check('[1]' => 'check_value');
    }
}
