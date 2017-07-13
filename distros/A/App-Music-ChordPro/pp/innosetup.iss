[Setup]
AppID={{F8D1018C-AAE3-45E6-9447-5997F512F932}
AppName=ChordPro
AppVersion=0.78.0.0
AppVerName=ChordPro 0.78
AppPublisher=Squirrel Consultancy
DefaultDirName={pf}\Squirrel Consultancy\ChordPro
DefaultGroupName=\Squirrel Consultancy\ChordPro
OutputDir=C:\Users\Johan\Documents\ChordPro
OutputBaseFilename=ChordPro-0-78-0-0-x64
Compression=lzma/Max
SolidCompression=true
AppCopyright=Copyright (C) 2017 Squirrel Consultancy
PrivilegesRequired=none
InternalCompressLevel=Max
ShowLanguageDialog=no
LanguageDetectionMethod=none
WizardImageFile=C:\Users\Johan\Documents\ChordPro\chordproinst.bmp

[Tasks]
Name: desktopicon; Description: "Create desktop icons"; GroupDescription: "Additional icons:"
Name: desktopicon\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked

[Files]
Source: C:\Users\Johan\Documents\ChordPro\wxchordpro.exe; DestDir: {app}\bin; Flags: ignoreversion recursesubdirs createallsubdirs overwritereadonly 64bit;

[Icons]
Name: {group}\ChordPro; Filename: {app}\bin\wxchordpro.exe; IconFilename: "C:\Users\Johan\Documents\ChordPro\chordpro.ico";
Name: "{group}\{cm:UninstallProgram,ChordPro}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\ChordPro"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\common; IconFilename: "C:\Users\Johan\Documents\ChordPro\chordpro.ico";
Name: "{userdesktop}\ChordPro"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\user; IconFilename: "C:\Users\Johan\Documents\ChordPro\chordpro.ico";

[Run]
Filename: "{app}\bin\wxchordpro"; Description: "Prepare"; Parameters: "--quit"; StatusMsg: "Preparing... (be patient)..."

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy
