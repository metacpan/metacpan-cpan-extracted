=begin comment

Copyright (c) 2019 Aspose Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut

package AsposeSlidesCloud::TestUtils;

use File::Slurp;
use Test::More;
use JSON;

use strict;
use warnings;
use utf8;

use AsposeSlidesCloud::Configuration;

my $is_initialized = 0;
my $test_data_version = "1";

sub new {
    my $class = shift;
    my %params = @_;
    my $config = AsposeSlidesCloud::Configuration->new();
    my $config_file = decode_json(read_file("testConfig.json"));
    $config->{base_url} = $config_file->{BaseUrl};
    $config->{auth_base_url} = $config_file->{AuthBaseUrl};
    $config->{app_sid} = $config_file->{AppSid};
    $config->{app_key} = $config_file->{AppKey};
    $config->{debug} = $config_file->{Debug};
    my $api = AsposeSlidesCloud::SlidesApi->new(config => $config);
    return bless { rules => decode_json(read_file('testRules.json')), api => $api }, $class;
}

sub initialize {
    my ($self, $function, $parameter, $parameter_value) = @_;
    $function =~ s/_//g;
    $parameter =~ s/_//g;
    if (!$is_initialized) {
        my %download_params = ('path' => 'TempTests/version.txt');
        my $version = $self->{api}->download_file(%download_params);
        if ($version != $test_data_version) {
            opendir my $dir, "TestData";
            my @files = readdir $dir;
            closedir $dir;
            foreach (@files) {
                if(-f "TestData\\".$_) {
                    my $content = read_file("TestData\\".$_, { binmode => ':raw' });
                    my %file_upload_params = ('path' => 'TempTests/'.$_, 'file' => $content);
                    $self->{api}->upload_file(%file_upload_params);
                }
            }
            my %upload_params = ('path' => 'TempTests/version.txt', 'file' => $test_data_version);
            $self->{api}->upload_file(%upload_params);
        }
        $is_initialized = 1;
    }

    my %files = ();
    my $fileRules = $self->{rules}->{Files};
    foreach (@$fileRules) {
        if ($self->is_good_rule($_, $function, $parameter)) {
            my $actual_name = $self->untemplatize($_->{File}, $parameter_value);
            my $path = "TempSlidesSDK";
            if (exists $_->{Folder}) {
                $path = $self->untemplatize($_->{Folder}, $parameter_value);
            }
            $path = $path."/".$actual_name;
            $files{$path} = $_;
            $_->{ActualName} = $actual_name;
        }
    }
    foreach my $path (keys %files) {
        if ($files{$path}->{Action} eq "Put") {
            my %copy_params = ('src_path' => 'TempTests/'.$files{$path}->{ActualName}, 'dest_path' => $path);
            $self->{api}->copy_file(%copy_params);
        } elsif ($files{$path}->{Action} eq "Delete") {
            my %delete_params = ('path' => $path);
            $self->{api}->delete_file(%delete_params);
        }
    }
}

# Set the user agent of the API client
#
# @param string $user_agent The user agent of the API client
#
sub get_param_value {
    my ($self, $function, $parameter, $type) = @_;
    $function =~ s/_//g;
    $parameter =~ s/_//g;
    if ($type eq 'File') {
        my $content = read_file("TestData\\test.ppt", { binmode => ':raw' });
        return $content;
    }
    my $result = "test".$parameter;
    my $values = $self->{rules}->{Values};
    foreach (@$values) {
        if ($self->is_good_rule($_, $function, $parameter)) {
            if (exists $_->{Value}) {
                $result = $_->{Value};
            }
        }
    }
    return $result;
}

sub invalidize_param_value {
    my ($self, $function, $parameter, $value) = @_;
    $function =~ s/_//g;
    $parameter =~ s/_//g;
    my $result = undef;
    my $values = $self->{rules}->{Values};
    foreach (@$values) {
        if ($self->is_good_rule($_, $function, $parameter)) {
            if (exists $_->{InvalidValue}) {
                $result = $_->{InvalidValue};
            }
        }
    }
    if (!$result) {
        return $result;
    }
    return $self->untemplatize($result, $value);
}

sub assert_error {
    my ($self, $function, $parameter, $value, $error) = @_;
    if ($error) {
        my $code = 0;
        my $message = "unexpected message";
        my $results = $self->{rules}->{Results};
        $function =~ s/_//g;
        $parameter =~ s/_//g;
        foreach (@$results) {
            if ($self->is_good_rule($_, $function, $parameter)) {
                if (exists $_->{Code}) {
                    $code = $_->{Code};
                }
                if (exists $_->{Message}) {
                    $message = $_->{Message};
                }
            }
        }
        if ($error =~ m/API Exception\((\d+)\): (.*) /s) {
            is($1, $code);
            ok(index($error, $self->untemplatize($message, $value)) != -1);
        } else {
            fail("strange exception for $function $parameter");
        }
    } else {
        fail("expected to fail for $function $parameter");
    }
}

sub assert_no_error {
    my ($self, $function, $parameter) = @_;
    my $results = $self->{rules}->{OKToNotFail};
    $function =~ s/_//g;
    $parameter =~ s/_//g;
    foreach (@$results) {
        if ($self->is_good_rule($_, $function, $parameter)) {
            pass();
            return;
        }
    }
    fail("expected to fail for $function $parameter");
}

sub is_good_rule {
    my ($self, $rule, $function, $parameter) = @_;
    if ((!(defined $rule->{Method}) or uc($rule->{Method}) eq uc($function))
        and (!(defined $rule->{Invalid}) or ($rule->{Invalid} eq defined $parameter))
        and (!(defined $rule->{Parameter}) or uc($rule->{Parameter}) eq uc($parameter))
        and (!(defined $rule->{Language}) or uc($rule->{Language}) eq "PERL")) {
        return 1;
    } else {
        return 0;
    };
}

sub untemplatize {
    my ($self, $template, $value) = @_;
    if (!$template) {
        return $value;
    } else {
        my $result = $template;
        if (defined $value) {
            $result =~ s/%v/$value/;
        } else {
            $result =~ s/%v//;
        }
        return $result;
    }
}

1;
