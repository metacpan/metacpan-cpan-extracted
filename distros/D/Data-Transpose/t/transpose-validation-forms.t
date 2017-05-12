use strict;
use warnings;
use Test::More tests => 63;
use Data::Transpose::Validator;
use Data::Dumper;

sub get_schema {

    my @schema = (
                  { name => 'institute',
                    validator => "String",
                    required => 1
                  },
                  { name => 'region',
                    validator => "String",
                    required => 1
                  },
                  { name => 'country',
                    validator => "String",
                    required => 1
                  },
                  { name => 'city',
                    validator => 'String',
                    required => 1
                  },
                  { name => 'type',
                    validator => 'String',
                    required => 1
                  },
                  { name => 'mail',
                    validator => 'EmailValid',
                  },
                  { name => 'mail2',
                    validator => 'EmailValid',
                  },
                  { name => 'website',
                    validator => 'URL',
                  },
                  { name => 'latitude',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => -90,
                                              max => 90,
                                             }
                                 }
                  },
                  { name => 'longitude',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => -180,
                                              max => 180,
                                             }
                                 }
                  },
                  { name => 'year',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => 1900,
                                              max => 2050,
                                              integer => 1,
                                             }
                                 }
                  },
                  { name => 'open',
                    validator => {
                                  class => 'Data::Transpose::Validator::Set',
                                  absolute => 1,
                                  options => {
                                              list => [qw/Yes No/],
                                             }
                                 }
                  }
                 );
    return \@schema;
}

# first case: all ok:

sub get_form {
    my %custom = @_;
    my $form = {
                institute => " Hey ",
                region => " Europe ",
                country => "Luxemburg",
                city => " L C ",
                type => " fake type ",
               };
    while (my ($k, $v) = each %custom) {
        $form->{$k} = $v;
    }
    return $form;
}

sub get_expected {
    my %custom = @_;
    my $form = {
                institute => "Hey",
                region => "Europe",
                country => "Luxemburg",
                city => "L C",
                type => "fake type",
               };
    while (my ($k, $v) = each %custom) {
        $form->{$k} = $v;
    }
    return $form;
    
}

      

my ($dtv, $clean, $expected);

$dtv = Data::Transpose::Validator->new();
$dtv->prepare(get_schema());
$clean = $dtv->transpose(get_form());
$expected = get_expected();

is_deeply($clean, $expected, "Transposed is what I expect to be");

print "Testing email\n";


sub test_form {
    my %spec = @_;
    my ($dtv, $form, $clean, $success, $expected);
    $dtv = Data::Transpose::Validator->new(%{$spec{dtvoptions}});
    $dtv->prepare(get_schema());
    $form = get_form(%{$spec{form}});
    $clean = $dtv->transpose($form);
    $success = $dtv->success;
    $expected = get_expected(%{$spec{expected}});

    if ($spec{debug}) {
        print Dumper($form, $clean, $expected)
    };
    
    if ($spec{fail}) {
        is($clean, undef, "transposing returns undef");
        ok($success == 0);
        if ($spec{debug}) {
            print Dumper($dtv->errors_as_hashref);
        }
        if ($spec{error_hash}) {
            is_deeply($dtv->errors_as_hashref, $spec{error_hash},
                      "Errors match");
        }
        ok($dtv->errors, $spec{message} . " " . $dtv->packed_errors);
    } else {
        ok($success);
        is_deeply($clean, $expected, $spec{message});
    }
}

test_form (
           dtvoptions => {},
           form => {},
           expected => {},
           message => "Plain test",
           fail => 0,
          );

test_form (
           dtvoptions => {},
           form => {mail => "invalid+ciao\@asdf_daslf"},
           expected => {},
           message => "Invalid email",
           error_hash => { mail => [ 'fqdn' ] },
           fail => 1,
           debug => 0,
          );

test_form (
           dtvoptions => {},
           form => {
                    mail => 'melmothx@google.it',
                    mail2 => 'invalid+ciao@asdf_daslf',
                   },
           expected => {},
           message => "Invalid email2",
           error_hash => { mail2 => [ 'fqdn' ] },
           fail => 1,
           debug => 0,
          );


test_form (
           dtvoptions => {},
           form => {
                    mail => 'melmothx@google.it',
                    mail2 => 'invalid+ciao@no-mx.asdf-daslf.it',
                   },
           expected => {},
           message => "Invalid email2",
           error_hash => { mail2 => [ 'mxcheck' ] },
           fail => 1,
           debug => 0,
          );

print "Testing all the required\n";

foreach my $requi (qw/institute region country city type/) {
    test_form (
               dtvoptions => {},
               form => {
                        $requi => ""
                   },
               expected => {},
               message => "Missing $requi",
               error_hash => { $requi => [ 'required' ] },
               fail => 1,
               debug => 0,
              );
}

print "Testing all the required with empty space\n";

foreach my $requi (qw/institute region country city type/) {
    test_form (
               dtvoptions => {},
               form => {
                        $requi => " "
                   },
               expected => {},
               message => "Missing $requi",
               error_hash => { $requi => [ 'required' ] },
               fail => 1,
               debug => 0,
              );
}

test_form (
           dtvoptions => {},
           form => {
                    mail => ' melmothx@google.it ',
                    mail2 => ' marco.erika@google.it ',
                   },
           expected => {
                        mail => 'melmothx@google.it',
                        mail2 => 'marco.erika@google.it',
                       },
           message => "Mails are valid and whitespace stripped",
           #           error_hash => { mail2 => [ 'mxcheck' ] },
           fail => 0,
           debug => 0,
          );


test_form (
           dtvoptions => {},
           form => {
                    latitude => -91,
                    longitude => "kadlfkj",
                    year => "lksdf",
                    open => 'yes',
                    website => 'ft__asdf',
                   },
           expected => {},
           message => "Wrong year, lat and long",
           error_hash => {
                          'longitude' => [
                                          'notanumber'
                                         ],
                          'latitude' => [
                                         'outofrange'
                                        ],
                          'year' => [ 'notanumber', 'notinteger' ],
                          'open' => [ 'missinginset' ],
                          website => [ 'badurl' ],
                         },
           fail => 1,
           debug => 0
          );


test_form (
           dtvoptions => {},
           form => {
                    latitude => " -89 ",
                    longitude => " 50 ",
                    year => " 2012 ",
                    open => ' Yes ',
                    website => ' http://google.it ',
                   },
           expected => {
                        latitude => -89,
                        longitude => 50,
                        year => 2012,
                        open => 'Yes',
                        website => 'http://google.it',
                       },
           message => "Finally a good form!",
           fail => 0,
           debug => 1,
          );
