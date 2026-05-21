# DrivePlayer

A GTK3 desktop music player that streams audio files stored in Google Drive.

## Features

- Streams audio directly from Google Drive via mpv
- Local SQLite library of scanned folders and tracks
- Sidebar navigation by artist, album, genre, or folder
- Metadata enrichment via iTunes, MusicBrainz, and AcoustID fingerprinting
- Google Sheets sync for portable metadata across multiple devices
- Incremental folder sync (adds new files, removes deleted ones)
- OAuth2 authentication via Google::RestApi

## Requirements

### System packages

```
sudo apt-get install build-essential pkg-config libssl-dev mpv \
    libgtk-3-dev libglib2.0-dev libgirepository1.0-dev gir1.2-gtk-3.0
```

### CPAN dependencies

```
cpanm --installdeps .
```

Or install everything in one step:

```
make install
```

## Setup

### 1. Create Google Cloud credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a project
2. Enable the **Google Drive API**: APIs & Services → Enable APIs → search "Drive API"
3. Create OAuth credentials: APIs & Services → Credentials → Create Credentials → OAuth client ID → **Desktop app**
4. Note the **Client ID** and **Client Secret**

### 2. Configure the application

Launch the app, open **File → Settings**, and paste the Client ID and Client Secret. Click Save.

The config file is written to `~/.config/drive_player/config.yaml`.

### 3. Authorise access to Google Drive

```
google_restapi_oauth_token_creator
```

Follow the prompts. The token is stored at `~/.config/drive_player/token.dat` by default.

### 4. Add music folders

Open **File → Manage Folders** and add the Google Drive folder ID (the last
path component of the folder's Drive URL) and a display name.

### 5. Sync

Click **Sync** in the toolbar or choose **Library → Sync** to scan your Drive
folders and populate the library.

## Cross-device sync via Google Sheets

DrivePlayer can store your library metadata in a Google Spreadsheet so it
survives across devices or a fresh install:

- **File → Settings**: enter or create a Spreadsheet ID
- Metadata is pushed to the sheet automatically after each sync
- On a new device, the sheet is pulled automatically when the app starts with
  an empty database, restoring your library without a full rescan

## Files

- `~/.config/drive_player/config.yaml` — OAuth credentials, log level, folder list
- `~/.config/drive_player/token.dat` — OAuth2 token cache
- `~/.local/share/drive_player/music.db` — SQLite track library
- `~/.local/share/drive_player/drive_player.log` — Application log

## License

MIT — see [LICENSE](LICENSE)
