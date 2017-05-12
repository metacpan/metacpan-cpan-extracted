# These are the constant settings for Encoding, Client and App
# Study launch.ica format and actual files sent by Citrix servers to configure these templates correctly
# Keep settings in Perl format.

# Short, static Section 'Encoding' (ISO/Latin 1 - ISO8859_1 - is a good universal default)
our $enc = {
   InputEncoding => 'ISO8859_1',
};

# Section 'WFClient'
our $client = {
   ClientName=> '',
   ProxyFavorIEConnectionSetting => Yes,
   ProxyTimeout => 30000,
   ProxyType => Auto,
   ProxyUseFQDN => Off,
   RemoveICAFile => yes,
   # Keyboard
   TransparentKeyPassthrough => FullScreenOnly,
   TransportReconnectEnabled => On,
   Version => 2,
   VirtualCOMPortEmulation => Off,
};

# Aplication Section static settings (Gets named on the fly during session message formatting)
our $app = {
   #Address => 'XX.XX.XX.192', # 
   #AutologonAllowed => ON,
   AutologonAllowed => OFF, # ON/OFF
   #ClearPassword => '', # Undocumented encrypted Citrix password (Not REALLY clear, but encrypted)
   ClientAudio => Off,
   Compress => On,
   DesiredColor => 8,
   #Domain => '', # Do not hard-wire here
   #InitialProgram => '#TERMINAL-UNIX', # Passed 
   Launcher => 'WI',
   LongCommandLine => '',
   ProxyTimeout => 30000,
   ProxyType => Auto,
   # Just for XML
   SSLEnable => Off,
   ScreenPercent => 90,
   #SessionsharingKey => '', # NA
   TWIMode => Off,
   TransportDriver => 'TCP/IP',
   #Username => '', # Do not hard-wire
   WinStationDriver => 'ICA 3.0',
};

