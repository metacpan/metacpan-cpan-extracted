# NAME

Android::ElectricSheep::Automator - Do Androids Dream of Electric Sheep? Smartphone control from your desktop.

# VERSION

Version 0.06

# WARNING

Current distribution is extremely alpha. API may change. 

# SYNOPSIS

The present package fascilitates the control
of a USB-debugging-enabled
Android device, e.g. a real smartphone,
or an emulated (virtual) Android device,
from your desktop computer using Perl.
It's basically a thickishly-thin wrapper
to the omnipotent Android Debug Bridge (adb)
program.

**Note that absolutely nothing is
installed on the connected device,
neither any of its settings will be modified by this package**.
See ["WILL ANYTHING BE INSTALLED ON THE DEVICE?"](#will-anything-be-installed-on-the-device).

    use Android::ElectricSheep::Automator;

    my $mother = Android::ElectricSheep::Automator->new({
      # optional as there is a default, but you may have
      # problems with the location of the adb executable
      'configfile' => $configfile,
      'verbosity' => 1,
      # we already have a device connected and ready to control
      'device-is-connected' => 1,
    });

    # find the devices connected to desktop and set one.
    my @devices = $mother->adb->devices;
    $mother->connect_device({'serial' => $devices->[0]->serial})
        or die;
    # no device needs to be specified if just one:
    $mother->connect_device() if scalar(@devices)==0;

    # Go Home
    $mother->home_screen() or die;

    # swipe up/down/left/right
    $mother->swipe({'direction'=>up}) or die;
    # dt is the time to swipe in millis,
    # the shorter the faster the swipe
    $mother->swipe({'direction'=>left, 'dt'=>100}) or die;

    # tap
    $mother->tap({'position'=>[100,200]});

    # uses swipe() to move in screens (horizontally):
    $mother->next_screen() or die;
    $mother->previous_screen() or die;

    # bottom navigation:
    # the "triangle" back button
    $mother->navigation_menu_back_button() or die;
    # the "circle" home button
    $mother->navigation_menu_home_button() or die;
    # the "square" overview button
    $mother->navigation_menu_overview_button() or die;

    # open/close apps
    $mother->open_app({'package'=>qr/calendar$/i}) or die;
    $mother->close_app({'package'=>qr/calendar$/i}) or die;

    # push pull files
    $mother->adb->pull($deviceFile, $localFile);
    $mother->adb->push($localFile, $deviceFileOrDir);

    # guess what!
    my $xmlstr = $mother->dump_current_screen_ui();

# CONSTRUCTOR

## new($params)

Creates a new `Android::ElectricSheep::Automator` object. `$params`
is a hash reference used to pass initialization options which may
or should include the following:

- **`confighash`** or **`configfile`**

    the configuration
    file holds
    configuration parameters and its format is "enhanced" JSON
    (see ["use Config::JSON::Enhanced"](#use-config-json-enhanced)) which is basically JSON
    which allows comments between ` </* ` and ` */> `.

    Here is an example configuration file to get you started:

        {
          "adb" : {
              "path-to-executable" : "/usr/local/android-sdk/platform-tools/adb"
          },
          "debug" : {
              "verbosity" : 0,
              </* cleanup temp files on exit */>
              "cleanup" : 1
          },
          "logger" : {
              </* log to file if you uncomment this, else console */>
              "filename" : "my.log"
          }
        }

    All sections in the configuration are mandatory.
    Setting `"adb"` to the wrong path will yield problems.

    `confighash` is a hash of configuration options with
    structure as above and can be supplied to the constructor
    instead of the configuration file.

    If no configuration is specified, then a default
    configuration will be used. In this case please
    specify **`adb-path-to-executable`** to point
    to the location of `adb`. Most likely
    the default path will not work for you.

- **`adb-path-to-executable`**

    optionally specify the path to the `adb` executable in
    your desktop system. This will override the setting
    ` 'adb'->'path-to-executable' ` in the configuration,
    if it was provided. Use this option if you are not
    providing any configuration and so the default configuration
    will be used. But it will most likely fail because of this
    path not being correct for your system. So, if you are going
    to omit providing a configuration and the default configuration
    will be used do specify the `adb` path via this option (but you
    don't have to and your mileage may vary).

- **`device-serial`** or **`device-object`**

    optionally specify the serial
    of a device to connect to on instantiation,
    or a [Android::ElectricSheep::Automator::DeviceProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3ADeviceProperties)
    object you already have handy. Alternatively,
    use ["connect\_device($params)"](#connect_device-params) to set the connected device at a later
    time. Note that there is no need to specify a
    device if there is exactly one connected device.

- **`adb`**

    optionally specify an already created [Android::ADB](https://metacpan.org/pod/Android%3A%3AADB) object.
    Otherwise, a fresh object will be created based
    on the configuration under the `adb` section of the configuration.

- **`device-is-connected`**

    optionally set it to 1
    in order to communicate with the device
    and get some information about it like
    screen size, resolution, orientation, etc.
    And also allow use of
    functionality which needs communicating with a device
    like ["swipe($params)"](#swipe-params), ["home\_screen($params)"](#home_screen-params),
    ["open\_app($params)"](#open_app-params), etc.
    After instantiation, you can use the
    method ["connect\_device($params)"](#connect_device-params) and
    ["disconnect\_device()"](#disconnect_device) for conveying
    this information to the module.
    Also note that if there are
    more than one devices connected to the desktop, make sure
    you specify which one with the `device` parameter.
    Default value is 0.

- **`logger`**

    optionally specify a logger object
    to be used (instead of creating a fresh one). This object
    must implement `info()`, `warn()`, `error()`. For
    example [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog).

- **`logfile`**

    optionally specify a file to
    save logging output to. This overrides the `filename`
    key under section `logger` of the configuration.

- **`verbosity`**

    optionally specify a verbosity level
    which will override what the configuration contains. Default
    is `0`.

- **`cleanup`**

    optionally specify a flag to clean up
    any temp files after exit which will override what the
    configuration contains. Default is `1`, meaning Yes!.

# METHODS

Note:

- **`ARRAY_REF`** : `my $ar = [1,2,3]; my $ar = \@ahash; my @anarray = @$ar;`
- **`HASH_REF`** : `my $hr = {1=`1, 2=>2}; my $hr = \\%ahash; my %ahash = %$hr;>
- In this module parameters to functions are passed as a HASH\_REF.
Functions return back objects, ARRAY\_REF or HASH\_REF.

- devices()

    Lists all Android devices connected to your
    desktop and returns these as an ARRAY\_REF which can be empty.

    It returns `undef` on failure.

- connect\_device($params)

    Specifies the current Android device to control. Its use is
    required only if you have more than one devices connected.
    `$params` is a HASH\_REF which should contain exactly
    one of the following:

    - **`serial`** should contain
    the serial (string) of the connected device as returned
    by ["devices()"](#devices).
    - **`device-object`** should be
    an already existing [Android::ElectricSheep::Automator::DeviceProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3ADeviceProperties)
    object.

    It returns `0` on success, `1` on failure.

- dump\_current\_screen\_ui($params)

    It dumps the current screen as XML and returns that as
    a string, optionally saving it to the specified file.

    `$params` is a HASH\_REF which may or should contain:

    - **`filename`**

        optionally save the returned XML string to the specified file.

    It returns `undef` on failure or the UI XML dump, as a string, on success.

- dump\_current\_screen\_shot($params)

    It dumps the current screen as a PNG image and returns that as
    a [Image::PNG](https://metacpan.org/pod/Image%3A%3APNG) object, optionally saving it to the specified file.

    `$params` is a HASH\_REF which may or should contain:

    - **`filename`**

        optionally save the returned XML string to the specified file.

    It returns `undef` on failure or a [Image::PNG](https://metacpan.org/pod/Image%3A%3APNG) image, on success.

- dump\_current\_screen\_video($params)

    It dumps the current screen as MP4 video and saves that
    in specified file.

    `$params` is a HASH\_REF which may or should contain:

    - **`filename`**

        save the recorded video to the specified file in MP4 format. This
        is required.

    - **`time-limit`**

        optionally specify the duration of the recorded video, in seconds. Default is 10 seconds.

    - **`bit-rate`**

        optionally specify the bit rate of the recorded video in bits per second. Default is 20Mbps.

        \# Optionally specify %size = ('width' => ..., 'height' => ...)

    - **`size`**

        optionally specify the size (geometry) of the recorded video as a
        HASH\_REF with keys `width` and `height`, in pixels. Default is "_the
        device's main display resolution_".

    - **`bugreport`**

        optionally set this flag to 1 to have Android overlay debug information
        on the recorded video, e.g. timestamp.

        \# Optionally specify 'display-id'.
        &#x3d;item **`display-id`**

        for a device set up with multiple physical displays, optionally
        specify which one to record -- if not the main display -- by providing the
        display id. You can find display ids with ["list\_physical\_displays()"](#list_physical_displays)
        or, from the CLI, by `adb shell dumpsys SurfaceFlinger --display-id`

    `adb shell screenrecord --help` contains some more documentation.

- list\_running\_processes($params)

    It finds the running processes on device (using a \`ps\`),
    optionally can save the (parsed) \`ps\`
    results as JSON to the specified 'filename'.
    It returns `undef` on failure or the results as a hash of hashes on success.

    `$params` is a HASH\_REF which may or should contain:

    - **`extra-fields`**

        optionally add more fields (columns) to the report by `ps`, as an ARRAY\_REF.
        For example, `['TTY','TIME']`.

    It needs that connect\_device() to have been called prior to this call

    It returns `undef` on failure or a hash with these keys on success:

    - **`raw`** : contains the raw \`ps\` output as a string.
    - **`perl`** : contains the parsed raw output as a Perl hash with
    each item corresponding to one process, keyed on process command and arguments
    (as reported by \`ps\`, verbatim), as a hash keyed on each field (column)
    of the \`ps\` output.
    - **`json`** : the above data converted into a JSON string.

- pidof($params)

    It returns the PID of the specified command name.
    The specified command name must match the app or command
    name exactly. **Use `pgrep()` if you want to match command
    names with a regular expression**.

    `$params` is a HASH\_REF which should contain:

    - **`name`**

        the name of the process. It can be a command name,
        e.g. `audioserver` or an app name e.g. `android.hardware.vibrator-service.example`.

    It returns `undef` on failure or the PID of the matched command on success.

- pgrep($params)

    It returns the PIDs matching the specified command or app
    name (which can be an extended regular expression that `pgrep`
    understands). The returned array will contain zero, one or more
    hashes with keys `pid` and `command`. The former key is the pid of the command
    whose full name (as per the process table) will be under the latter key.
    Unless parameter `dont-show-command-name` was set to `1`.

    `$params` is a HASH\_REF which should contain:

    - **`name`**

        the name of the process. It can be a command name,
        e.g. `audioserver` or an app name e.g. `android.hardware.vibrator-service.example`
        or part of these e.g. `audio` or `hardware` or an extended
        regular expression that Android's `pgrep` understands, e.g.
        `^com.+google.+mess`.

    It returns `undef` on failure or an ARRAY\_REF containing
    a HASH\_REF of data for each command matched (under keys `pid` and `command`).
    The returned ARRAY\_REF can contain 0, 1 or more items depending
    on what was matched.

- geofix($params)

    It fixes the geolocation of the device to the specified coordinates.
    After this, app API calls to get current geolocation will result to this
    position (unless they use their own, roundabout way).

    `$params` is a HASH\_REF which should contain:

    - **`latitude`**

        the latitude of the position as a floating point number.

    - **`longitude`**

        the longitude of the position as a floating point number.

    It returns `1` on failure or a `0` on success.

- dump\_current\_location()

    It finds the current GPS location of the device
    according to ALL the GPS providers available.

    It needs that connect\_device() to have been called prior to this call

    It takes no parameters.

    On failure, it returns `undef`.

    On success, it returns a HASH\_REF of results.
    Each item will be keyed on provider name (e.g. '`network provider`')
    and will contain the parsed output of
    what each GPS provider returned as a HASH\_REF with
    the following keys:

    - **`provider`** : the provider name. This is also the key of the item
    in the parent hash.
    - **`latitude`** : the latitude as a floating point number (can be negative too)
    or ` <na> ` if the provider failed to return valid output.
    - **`longitude`** : the longitude as a floating point number (can be negative too)
    or ` <na > ` if the provider failed to return valid output.
    - **`last-location-string`** : the last location string, or
    ` <na > ` if the provider failed to return valid output.

- is\_app\_running($params)

    It checks if the specified app is running on the device.
    The name of the app must be exact.
    Note that you can search for running apps / commands
    with extended regular expressions using `pgrep()`

    `$params` is a HASH\_REF which should contain:

    - **`appname`**

        the name of the app to check if it is running.
        It must be its exact name. Basically it checks the
        output of `pidof()`.

    It returns `undef` on failure,
    `1` if the app is running or `0` if the app is not running.

- find\_current\_device\_properties($params)

    It enquires the device currently connected,
    and specified with ["connect\_device($params)"](#connect_device-params), if needed,
    and returns back an [Android::ElectricSheep::Automator::DeviceProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3ADeviceProperties)
    object containing this information, for example screen size,
    resolution, serial number, etc.

    It returns [Android::ElectricSheep::Automator::DeviceProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3ADeviceProperties)
    object on success or `undef` on failure.

- connect\_device()

    It signals to our object that there is now
    a device connected to the desktop and its
    enquiry and subsequent control can commence.
    If this is not called and neither `device-is-connected => 1`
    is specified as a parameter to the constructor, then
    the functionality will be limited and access
    to functions like `swipe()`, `open_app()`, etc.
    will be blocked until the caller signals that
    a device is now connected to the desktop.

    Using ["connect\_device($params)"](#connect_device-params) to specify which device
    to target in the case of multiple devices
    connected to the desktop will also call this
    method.

    This method will try to enquire the connected device
    about some of its properties, like screen size,
    resolution, orientation, serial number etc.
    This information will subsequently be available
    via `$self->`device\_properties()>.

    It returns `0` on success, `1` on failure.

- disconnect\_device()

    Signals to our object that it should consider
    that there is currently no device connected to
    the desktop (irrespective of that is true or not)
    which will block access to ["swipe()"](#swipe), ["open\_app()"](#open_app), etc.

- device\_properties()

    It returns the currently connected device properties
    as a [Android::ElectricSheep::Automator::DeviceProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3ADeviceProperties)
    object or `undef` if there is no connected device.
    The returned object is constructed during a call
    to ["find\_current\_device\_properties()"](#find_current_device_properties)
    which is called via ["connect\_device($params)"](#connect_device-params) and will persist
    for the duration of the connection.
    However, after a call to ["disconnect\_device()"](#disconnect_device)
    this object will be discarded and `undef` will be
    returned.

- swipe($params)

    Emulates a "swipe" in four directions.
    Sets the current Android device to control. It is only
    required if you have more than one device connected.
    `$params` is a HASH\_REF which may or should contain:

    - **`direction`**

        should be one of

        - up
        - down
        - left
        - right

    - **`dt`**

        denotes the time taken for the swipe
        in milliseconds. The smaller its value the faster
        the swipe. A value of `100` is fast enough to swipe to
        the next screen.

    It returns `0` on success, `1` on failure.

- tap($params)

    Emulates a "tap" at the specified location.
    `$params` is a HASH\_REF which must contain one
    of the following items:

    - **`position`**

        should be an ARRAY\_REF
        as the `X,Y` coordinates of the point to "tap".

    - **`bounds`**

        should be an ARRAY\_REF of a bounding rectangle
        of the widget to tap. Which contains two ARRAY\_REFs
        for the top-left and bottom-right coordinates, e.g.
        ` [ [tlX,tlY], [brX,brY] ] `. This is convenient
        when the widget is extracted from an XML dump of
        the UI (see ["dump\_current\_screen\_ui()"](#dump_current_screen_ui)) which
        contains exactly this bounding rectangle.

    It returns `0` on success, `1` on failure.

- input\_text($params)

    It "`types`" the specified text into the specified position,
    where a text-input widget is expected to exist.
    At first it taps at the widget's
    location in order to get the focus. And then it enters
    the text. You need to find the position of the desired
    text-input widget by first getting the current screen UI
    (using [dump\_current\_screen\_ui](https://metacpan.org/pod/dump_current_screen_ui)) and then using an XPath
    selector to identify the desired widget by name/id/attributes.
    See the source code of method `send_message()` in file
    `lib/Android/ElectricSheep/Automator/Plugins/Apps/Viber.pm`
    for how this is done for the message-sending text-input widget
    of the Viber app.

    `$params` is a HASH\_REF which must contain `text`
    and one of the two position (of the text-edit widget)
    specifiers `position` or `bounds`:

    - **`text`**

        the text to write on the text edit widget. At the
        moment, this must be plain ASCII string, not unicode.
        No spaces are accepted.
        Each space character must be replaced with `%s`.

    - **`position`**

        should be an ARRAY\_REF
        as the `X,Y` coordinates of the point to "tap" in order
        to get the focus of the text edit widget, preceding the
        text input.

    - **`bounds`**

        should be an ARRAY\_REF of a bounding rectangle
        of the widget to tap, in order to get the focus, preceding
        the text input. Which contains two ARRAY\_REFs
        for the top-left and bottom-right coordinates, e.g.
        ` [ [tlX,tlY], [brX,brY] ] `. This is convenient
        when the widget is extracted from an XML dump of
        the UI (see ["dump\_current\_screen\_ui()"](#dump_current_screen_ui)) which
        contains exactly this bounding rectangle.

    It returns `0` on success, `1` on failure.

- clear\_input\_field($params)

    It clears the contents of a text-input widget
    at specified location.

    There are several ways to do this. The simplest way
    (with `keycombination`) does not work in some
    devices, in which case a failsafe way is employed
    which deletes characters one after the other for
    250 times. 

    `$params` is a HASH\_REF which must contain
    one of the two position (of the text-edit widget)
    specifiers `position` or `bounds`:

    - **`position`**

        should be an ARRAY\_REF
        as the `X,Y` coordinates of the point to "tap" in order
        to get the focus of the text edit widget, preceding the
        text input.

    - **`bounds`**

        should be an ARRAY\_REF of a bounding rectangle
        of the widget to tap, in order to get the focus, preceding
        the text input. Which contains two ARRAY\_REFs
        for the top-left and bottom-right coordinates, e.g.
        ` [ [tlX,tlY], [brX,brY] ] `. This is convenient
        when the widget is extracted from an XML dump of
        the UI (see ["dump\_current\_screen\_ui()"](#dump_current_screen_ui)) which
        contains exactly this bounding rectangle.

    - **`num-characters`**

        how many times to press the backspace? Default is 250!
        But if you know the length of the text currently at
        the text-edit widget then enter this here.

    It returns `0` on success, `1` on failure.

- home\_screen()

    Go to the "home" screen.

    It returns `0` on success, `1` on failure.

- wake\_up()

    "Wake" up the device.

    It returns `0` on success, `1` on failure.

- next\_screen()

    Swipe to the next screen (on the right).

    It returns `0` on success, `1` on failure.

- previous\_screen()

    Swipe to the previous screen (on the left).

    It returns `0` on success, `1` on failure.

- navigation\_menu\_back\_button()

    Press the "back" button which is the triangular
    button at the left of the navigation menu at the bottom.

    It returns `0` on success, `1` on failure.

- navigation\_menu\_home\_button()

    Press the "home" button which is the circular
    button in the middle of the navigation menu at the bottom.

    It returns `0` on success, `1` on failure.

- navigation\_menu\_overview\_button()

    Press the "overview" button which is the square
    button at the right of the navigation menu at the bottom.

    It returns `0` on success, `1` on failure.

- apps()

    It returns a HASH\_REF containing all the
    packages (apps) installed on the device
    keyed on package name (which is like `com.android.settings`.
    The list of installed apps is populated either
    if `device-is-connected` is set to 1 during construction
    or a call has been made to any of these
    methods: `open_app()`, `close_app()`,
    `search_app()`, `find_installed_apps()`.

- find\_installed\_apps($params)

    It enquires the device about all the installed
    packages (apps) it has for the purpose of
    opening and closing apps with `open_app()` and `close_app()`.
    This list is available using `$self-`apps>.

    Finding the package names is done in a single
    operation and does
    not take long. But enquiring with the connected device
    about the main activity/ies
    of each package takes some time as there should be
    one enquiry for each package. By default,
    `find_installed_apps()` will find all the package names
    but will not enquire each package (fast).
    This enquiry will be
    done lazily if and when you need to open or close that
    app.

    `$params` is a HASH\_REF which may or should contain:

    - **`packages`**

        is a list of package names to enquire
        about with the device. It can be a scalar string with the
        exact package name, e.g. `com.android.settings`, or
        a [Regexp](https://metacpan.org/pod/Regexp) object which is a compiled regular expression
        created by e.g. `qr/^\.com.+?\.settings$/i`, or
        an ARRAY\_REF of package names. Or a HASH\_REF where
        keys are package names. For each of the packages matched
        witht this specification a full enquiry will be made
        with the connected device. The information will
        be saved in a [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
        object and will include the main activity/ies, permissions requested etc.

    - **`lazy`**

        is a flag to denote whether to enquire
        information about each package (app) at the time of this
        call (set it to `1`) or lazily, on a if-and-when-needed basis
        (set it to `0` which is the default). `lazy` affects
        all packages except those specified in `packages`, if any.
        Default is `1`.

    - **`force-reload-apps-list'`**

        can be set to 1 to
        erase previous packages information and start fresh.
        Default is `0`.

    It returns a HASH\_REF of packages names (keys) along
    with enquired information (as a [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
    object) or `undef` if this information was not
    obtained (e.g. when `lazy` is set to 1).
    It also sets the exact same data to be available
    via `$self-`apps>.

- search\_app($params)

    It searches the list of installed packages (apps)
    on the current device and returns the match(es)
    as a HASH\_REF keyed on package name which may
    have as values [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
    objects with packages information. If there are
    no entries yet in the list of installed packages,
    it calls the `find_installed_apps()` first to populate it.

    `$params` is a HASH\_REF which may or should contain:

    - **`package`**

        is required. It can either be
        a scalar string with the exact package name
        or a [Regexp](https://metacpan.org/pod/Regexp) object which is a compiled regular expression
        created by e.g. `qr/^\.com.+?\.settings$/i`.

    - **`lazy`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, to denote whether to enquire
        information about each package (app) at the time of this
        call (set it to `1`) or lazily, on a if-and-when-needed basis
        (set it to `0` which is the default). `lazy` affects
        all packages except those specified in `packages`, if any. Default is `1`.

    - **`force-reload-apps-list'`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, and can be set to 1 to
        erase previous packages information and start fresh. Default is `0`.

    It returns a HASH\_REF of matched packages names (keys) along
    with enquired information (as a [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
    object) or `undef` if this information was not
    obtained (e.g. when `lazy` is set to 1).

- open\_app($params)

    It opens the package specified in `$params`
    on the current device. If there are
    no entries yet in the list of installed packages,
    it calls the `find_installed_apps()` first to populate it.
    It will refuse to open multiple apps matched perhaps
    by a regular expression in the package specification.

    `$params` is a HASH\_REF which may or should contain:

    - **`package`**

        is required. It can either be
        a scalar string with the exact package name
        or a [Regexp](https://metacpan.org/pod/Regexp) object which is a compiled regular expression
        created by e.g. `qr/^\.com.+?\.settings$/i`. If a regular
        expression, the call will fail if there is not
        exactly one match.

    - **`lazy`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, to denote whether to enquire
        information about each package (app) at the time of this
        call (set it to `1`) or lazily, on a if-and-when-needed basis
        (set it to `0` which is the default). `lazy` affects
        all packages except those specified in `packages`, if any. Default is `1`.

    - **`force-reload-apps-list'`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, and can be set to 1 to
        erase previous packages information and start fresh. Default is `0`.

    It returns a HASH\_REF of matched packages names (keys) along
    with enquired information (as a [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
    object). At the moment, because `open_app()` allows opening only a single app,
    this hash will contain only one entry unless we allow opening multiple
    apps (e.g. via a regex which it is already supported) in the future.

- close\_app($params)

    It closes the package specified in `$params`
    on the current device. If there are
    no entries yet in the list of installed packages,
    it calls the `find_installed_apps()` first to populate it.
    It will refuse to close multiple apps matched perhaps
    by a regular expression in the package specification.

    `$params` is a HASH\_REF which may or should contain:

    - **`package`**

        is required. It can either be
        a scalar string with the exact package name
        or a [Regexp](https://metacpan.org/pod/Regexp) object which is a compiled regular expression
        created by e.g. `qr/^\.com.+?\.settings$/i`. If a regular
        expression, the call will fail if there is not
        exactly one match.

    - **`lazy`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, to denote whether to enquire
        information about each package (app) at the time of this
        call (set it to `1`) or lazily, on a if-and-when-needed basis
        (set it to `0` which is the default). `lazy` affects
        all packages except those specified in `packages`, if any. Default is `1`.

    - **`force-reload-apps-list'`**

        is a flag to be passed on to ["find\_installed\_apps()"](#find_installed_apps),
        if needed, and can be set to 1 to
        erase previous packages information and start fresh. Default is `0`.

    It returns a HASH\_REF of matched packages names (keys) along
    with enquired information (as a [Android::ElectricSheep::Automator::AppProperties](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3AAppProperties)
    object). At the moment, because `close_app()` allows closing only a single app,
    this hash will contain only one entry unless we allow closing multiple
    apps (e.g. via a regex which it is already supported) in the future.

# SCRIPTS

For convenience, a few simple scripts are provided:

- **`script/electric-sheep-find-installed-apps.pl`**

    Find all install packages in the connected device. E.g.

    `script/electric-sheep-find-installed-apps.pl --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json`

    `script/electric-sheep-find-installed-apps.pl --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json --fast`

- **`script/electric-sheep-open-app.pl`**

    Open an app by its exact name or a keyword matching it (uniquely):

    `script/electric-sheep-open-app.pl --configfile config/myapp.conf --name com.android.settings`

    `script/electric-sheep-open-app.pl --configfile config/myapp.conf --keyword 'clock'`

    Note that it constructs a regular expression from escaped user input.

- **`script/electric-sheep-close-app.pl`**

    Close an app by its exact name or a keyword matching it (uniquely):

    `script/electric-sheep-close-app.pl --configfile config/myapp.conf --name com.android.settings`

    `script/electric-sheep-close-app.pl --configfile config/myapp.conf --keyword 'clock'`

    Note that it constructs a regular expression from escaped user input.

- **`script/electric-sheep-dump-ui.pl`**

    Dump the current screen UI as XML to STDOUT or to a file:

    `script/electric-sheep-dump-ui.pl --configfile config/myapp.conf --output ui.xml`

    Note that it constructs a regular expression from escaped user input.

- **`script/electric-sheep-dump-current-location.pl`**

    Dump the GPS / geo-location position for the device from its various providers, if enabled.

    `script/electric-sheep-dump-current-location.pl --configfile config/myapp.conf --output geolocation.json`

- **`script/electric-sheep-emulator-geofix.pl`**

    Set the GPS / geo-location position to the specified coordinates.

    `script/electric-sheep-dump-ui.pl --configfile config/myapp.conf --latitude 12.3 --longitude 45.6`

- **`script/electric-sheep-dump-screen-shot.pl`**

    Take a screenshot of the device (current screen) and save to a PNG file.

    `script/electric-sheep-dump-screen-shot.pl --configfile config/myapp.conf --output screenshot.png`

- **`script/electric-sheep-dump-screen-video.pl`**

    Record a video of the device's current screen and save to an MP4 file.

    `script/electric-sheep-dump-screen-video.pl --configfile config/myapp.conf --output video.mp4 --time-limit 30`

- **`script/electric-sheep-viber-send-message.pl`**

    Send a message using the Viber app.

    `script/electric-sheep-viber-send-message.pl --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf --device Pixel_2_API_30_x86_>>`

    This one saves a lot of debugging information to `debug` which can be used to
    deal with special cases or different versions of Viber:

    `script/electric-sheep-viber-send-message.pl --outbase debug --verbosity 1 --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf --device Pixel_2_API_30_x86_>>`

# TESTING

The normal tests under `t/`, initiated with `make test`,
are quite limited in scope because they do not assume
a connected device. That is, they do not check any
functions which require interaction with a connected
device.

The _live tests_ under `xt/live`, initiated with
`make livetest`, require
an Android device connected to your desktop on which
you installed this package and on which you are doing the testing.
This suffices to be an emulator. It can also be a real Android
phone but testing
with your smartphone is not a good idea, please do not do this,
unless it is some phone which you do not store important data.

So, prior to `make livetest` make sure you have an android
emulator up and running with, for example,
`emulator -avd Pixel_2_API_30_x86_` . See section
["Android Emulators"](#android-emulators) for how to install, list and run them
buggers.

Testing will not send any messages via the device's apps.
E.g. the plugin [Android::ElectricSheep::Automator::Plugins::Apps::Viber](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator%3A%3APlugins%3A%3AApps%3A%3AViber)
will not send a message via Viber but it will mock it.

The live tests will sometimes fail because, so far,
something unexpected happened in the device. For example,
in testing sending input text to a text-edit widget,
the calendar will be opened and a new entry will be added
and its text-edit widget will be targeted. Well, sometimes
the calendar app will give you some notification
on startup and this messes up with the focus.
Other times, the OS will detect that some app is taking too
long to launch and pops up a notification about
"_something is not responding, shall I close it_".
This steals the focus and sometimes it causes
the tests to fail.

# PREREQUISITES

## Android Studio

This is not a prerequisite but it is
highly recommended to install
(from [https://developer.android.com/studio](https://developer.android.com/studio))
on your desktop computer because it contains
all the executables you will need,
saved in a well documented file system hierarchy,
which can then be accessed from the command line.

Additionally, Android Studio offers possibly the
easiest way to create Android Virtual Devices (AVD) which emulate
an Android phone of various specifications.
I mention this because one can install apps
on an AVD and control them from your desktop
as long as you are able to receive sms verification
codes from a real phone. This is great for
experimenting without pluggin in your real
smartphone on your desktop.

The bottom line is that by installing Android Studio,
you have all the executables you need for running things
from the command line and, additionally, you have
the easiest way for creating Android
Virtual Devices, which emulate Android devices: phones,
tablets, automotive displays. Once you have this set up, you
will not need to open Android Studio ever again unless you
want to update your kit. All the functionality
will be accessible from the command line.

## ADB

Android Debug Bridge (ADB) is the program
which communicates with your smartphone or
an Android Virtual Device from
your desktop (Linux, osx and the unnamed `0$`).

If you do not want to install Android Studio, the `adb` executable
is included in the package called
"Android SDK Platform Tools" available from
the Android official site, here:
[https://developer.android.com/tools/releases/platform-tools#downloads](https://developer.android.com/tools/releases/platform-tools#downloads)

You will need the `adb` executable to be on your path
or specify its fullpath in the configuration file
supplied to [Android::ElectricSheep::Automator](https://metacpan.org/pod/Android%3A%3AElectricSheep%3A%3AAutomator)'s constructor.

## USB Debugging

The targeted smartphone must have "USB Debugging" enabled
via the "Developer mode".
This is not
to be confused with 'rooted' or 'jailbroken' modes, none of
these are required for experimenting with the current module.

In order to enable "USB Debugging", you need
to set the smartphone to enter "Developer" mode by
following this procedure:

Go to `Settings->System->About Phone`
Tap on `Build Number` 7 times \[sic!\].
Enter your phone pin and you are in developer mode.

You can exit Developer Mode by going to
`Settings->System->Developer` and turn it off.
It is highly advised to turn off Developer Mode
for everyday use of your phone.
**Do not connect your smartphone
to public WIFI networks with Developer Mode ON**.

**Do not leave home with Developer Mode ON**.

Once you have enabled "USB Debugging", you have
two options for making your device visible to
your desktop and, consequently, to ADB and to this module:

- connect your android device via a USB cable
to your desktop computer. I am not sure if you also
need to tap on the USB charging options and allow
"Transfer Files".
- connect your device to the same WIFI network
as your desktop computer. Then follow instructions
from, e.g., here [https://developer.android.com](https://developer.android.com).
This requires a newer Android version.

## Android Emulators

It is possible to do most things your
smartphone does with an Android Virtual Device.
You can install apps on the the virtual device which
you can register by supplying your real smartphone
number.

List all virtual devices currently available
in your desktop computer,  with `emulator -list-avds`
which outputs something like:

    Pixel_2_API_27_x86_
    Pixel_2_API_30_x86_

Start a virtual device with `emulator -avd Pixel_2_API_30_x86_`

And hey, you have an android phone running on your
desktop in its own space, able to access the network
but not the telephone network (no SIM card).

It is possible to create a virtual device
from the command line.
But perhaps it is easier if you download Android Studio
from: [https://developer.android.com/studio](https://developer.android.com/studio) and follow
the setup there using the GUI. You will need to do this just
once for creating the device, you can then uninstall Android Studio.

Android Studio will download all the
required files and will create some Android Virtual
Devices (the "emulators") for you. It will also be easy to
update your stack in the future. Once you have done the above,
you no longer need to run Android Studio except perhaps for
checking for updates and **all the required executables by this
package will be available from the command line**.

Otherwise, download "Android SDK Platform Tools" available from
the Android official site, here:
[https://developer.android.com/tools/releases/platform-tools#downloads](https://developer.android.com/tools/releases/platform-tools#downloads)
(this download is mentioned in [ADB](https://metacpan.org/pod/ADB) if you already fetched it).

Fetch the required packages with this command:

`sdkmanager --sdk_root=/usr/local/android-sdk  "platform-tools" "platforms;android-30" "cmdline-tools;latest" "emulator"`

Note that `sdkmanager --list` will list the latest android versions etc.

Now you should have access to `avdmanager` executable
(it should be located here: `/usr/local/android-sdk/cmdline-tools/latest/bin/avdmanager`)
which you can use to create an emulator.

List all available android virtual devices you can create: `avdmanager list target`

List all available devices you can emulate: `avdmanager list device`

List all available devices you have created already: `avdmanager list avd`

Create virtual device: `avdmanager create avd -d "Nexus 6" -n myavd -k "system-images;android-29;google_apis;x86"`

See [https://stackoverflow.com/a/77599934](https://stackoverflow.com/a/77599934)

# USING YOUR REAL SMARTPHONE

Using your real smartphone
with such a powerful tool may not be such
a good idea.

One can only imagine what
kind of viruses MICROSOFT WINDOWS can pass on to an
Android device connected to it. Refrain from doing
so unless you are using a more secure OS.

Start with an emulator.

# WILL ANYTHING BE INSTALLED ON THE DEVICE?

Absolutely NOTHING!

This package
**does not mess with the connected device,
neither it installs anything on it
neither it modifies
any of its settings**. Unless the user explicitly
does something, e.g. explicitly
a user installs / uninstalls apps
programmatically using this package.

Unlike this Python library:
[https://github.com/openatx/uiautomator2](https://github.com/openatx/uiautomator2),
(not to be confused with google's namesake),
which sneakily installs their ADB server to your device!

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-Android-ElectricSheep-Automator at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ElectricSheep-Automator](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ElectricSheep-Automator).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ElectricSheep-Automator](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ElectricSheep-Automator)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Android-ElectricSheep-Automator](http://annocpan.org/dist/Android-ElectricSheep-Automator)

- Search CPAN

    [https://metacpan.org/release/Android-ElectricSheep-Automator](https://metacpan.org/release/Android-ElectricSheep-Automator)

# SEE ALSO

- [Android::ADB](https://metacpan.org/pod/Android%3A%3AADB) is a thin wrapper of the `adb` command
created by Marius Gavrilescu, `marius@ieval.ro`.
It is used by current module, albeit modified.

# HUGS

- Πτηνού, my chicken now laying in the big coop in the sky ...

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 2362:

    '=item' outside of any '=over'

- Around line 2392:

    '=item' outside of any '=over'

- Around line 2471:

    '=item' outside of any '=over'

- Around line 3012:

    Unterminated C< ... > sequence

- Around line 3017:

    Unterminated C< ... > sequence
