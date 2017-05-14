### NAME

logcat_format - pretty print android adb logcat output

### DESCRIPTION

A tool to pretty print the output of the android sdk 'adb logcat' command.

Before 

<p><img src="https://raw.github.com/vichou/App-logcat_format/master/screenshots/before.png"
alt="Before" /></p>

After

<p><img src="https://raw.github.com/vichou/App-logcat_format/master/screenshots/after.png"
alt="Before" /></p>

### SYNOPSIS

Default adb logcat pretty print ..

    % logcat_format 

For default logcat output for emulator only ..

    % logcat_format -e 

For default logcat output for device only ..

    % logcat_format -d

For other adb logcat commands, just pipe into logcat_format ..

    % adb logcat -v threadtime | logcat_format
    % adb -e logcat -v process | logcat_format

### VERSION

version 0.06
