BEGIN { $ENV{CLEARCASE_CLEARPROMPT_TEST_EV} = 'L:\\aaa\\bbb\\ccc' }
use ClearCase::ClearPrompt qw(/ENV);

for (keys %ENV) {
    print "\%$_%=$ENV{$_}\n" if $ENV{$_} =~ m%/%;
}
