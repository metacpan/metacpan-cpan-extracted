#!/usr/bin/env perl

use strict;
use warnings 'all';

use BZ::Client::XMLRPC::Parser;

use Test::More tests => 5;

sub parse {
    my $contents = shift;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    my $result;
    eval {
        $result = $parser->parse($contents);
    };
    if ($@) {
        my $msg;
        if (ref($@) eq 'BZ::Client::Exception') {
            $msg = $@->message();
        } else {
            $msg = $@;
        }
        diag $msg;
        return undef;
    }
    return $result;
}

sub parse_error {
    my $contents = shift;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    my $result;
    eval {
        $result = $parser->parse($contents);
    };
    if (!$@) {
        diag 'Expected exception, got none.';
        return undef;
    }
    if (ref($@) ne 'BZ::Client::Exception') {
        diag $@;
        return undef;
    }
    return $@;
}

sub TestBasic {
    my $doc = <<'EOF';
<methodResponse>
    <params>
        <param>
            <value><string>South Dakota</string></value>
        </param>
    </params>
</methodResponse>
EOF
    return parse($doc);
}

sub TestStrings {
    my $doc = <<'EOF';
<methodResponse>
    <params>
        <param>
            <value>
              <array>
                <data>
                  <value><string>South Dakota</string></value>
                  <value>North Dakota</value>
                  <value><dateTime.iso8601>2011-06-04T20:15:17Z</dateTime.iso8601></value>
                </data>
              </array>
            </value>
        </param>
    </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result  ||  ref($result) ne 'ARRAY') {
        return 'Expected array, got ' . (defined($result) ? $result : 'undef');
    }
    if (@$result != 3) {
        return 'Expected 3 result elements, got ' . scalar(@$result);
    }
    my $res0 = $result->[0];
    if (!$res0  ||  $res0 ne 'South Dakota') {
        return "Expected first result element to be 'South Dakota', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    my $res1 = $result->[1];
    if (!$res1  ||  $res1 ne 'North Dakota') {
        return "Expected first result element to be 'North Dakota', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    my $res2 = $result->[2];
    if ('DateTime' ne ref($res2)){
      return 'Expected DateTime, got '. ref($res2);
    }
    if ($res2->year != 2011){
      return 'Expected year 2022, got ' . $res2-> year();
    }
    if ($res2->month != 6){
      return 'Expected month 6, got ' . $res2->month();
    }
    if ($res2->day != 4){
      return 'Expected day 4, got ' . $res2->day();
    }
    if ($res2->hour != 20){
      return 'Expected hour 20, got ' . $res2->hour();
    }
    if ($res2->minute != 15){
      return 'Expected minute 15, got ' . $res2->minute();
    }
    if ($res2-> second != 17){
      return 'Expectead second 17, got ' . $res2->second();
    }
    if ($res2->time_zone->name() ne 'UTC'){
      return 'Expectead timezone UTC, got ' . $res2->time_zone->name();
    }

    return undef;
}

sub TestStructure {
    my $doc = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>foo</name>
            <value>bar</value>
          </member>
          <member>
            <name>yum</name>
            <value>yam</value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result || ref($result) ne 'HASH') {
        return 'Expected hash, got ' . (defined($result) ? $result : 'undef');
    }
    if ((keys %$result) != 2) {
        return 'Expected 2 result members, got ' . scalar(keys %$result);
    }
    my $res0 = $result->{'foo'};
    if (!$res0 || $res0 ne 'bar') {
        return "Expected result member 'foo' to be 'bar', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    my $res1 = $result->{'yum'};
    if (!$res1 || $res1 ne 'yam') {
        return "Expected result member 'yum' to be 'yam', got " . (defined($res1) ? "'$res1'" : "undef");
    }
    return undef;
}

sub TestFault {
    my $doc = <<'EOF';
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value>401343</value>
        </member>
        <member>
          <name>faultString</name>
          <value>Some problem occurred</value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
EOF
    my $result = parse_error($doc);
    my $code = $result->xmlrpc_code();
    if (!defined($code)  ||  $code != 401343) {
        return 'Expected faultCode 401343, got ' . (defined($code) ? $code : 'undef');
    }
    my $message = $result->message();
    if (!defined($message) || $message ne 'Some problem occurred') {
        return q|Expected faultString 'Some problem occurred', got | . (defined($message) ? "'$message'" : "undef");
    }
    my $http_code = $result->http_code();
    if (defined($http_code)) {
        return 'Expected no http_code, got ' . $http_code;
    }
    return undef;
}

sub TestLogin {
    my $doc = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>id</name>
            <value><int>1</int></value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result || ref($result) ne 'HASH') {
        return 'Expected hash, got ' . (defined($result) ? $result : 'undef');
    }
    if ((keys %$result) != 1) {
        return 'Expected 1 result member, got ' . scalar(keys %$result);
    }
    my $res0 = $result->{'id'};
    if (!$res0 || $res0 ne '1') {
        return "Expected result member 'id' to be '1', got " . (defined($res0) ? "'$res0'" : 'undef');
    }
    return undef;
}

# This is kind of strange due to being originally for Test rather than Test::More
ok(TestBasic() eq 'South Dakota', 'Basic Test');
my $res = TestStrings();
ok(!$res, 'Test Strings') or diag($res);
$res = TestStructure();
ok(!$res, 'Test Structure') or diag($res);
$res = TestFault();
ok(!$res, 'Test Fault') or diag($res);
$res = TestLogin();
ok(!$res, 'Test Login') or diag($res);
