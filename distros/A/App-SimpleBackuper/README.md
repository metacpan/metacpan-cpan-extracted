[![CPAN](https://img.shields.io/cpan/v/App-SimpleBackuper.svg)](https://metacpan.org/release/App-SimpleBackuper)

# What's this
**Simple-backuper** is a simple tool for backuping files and restoring it from backups.

# Benefits
- Simplicity and transparency. Few lib files and one short script. Most programmers can understand it.
- Efficient use of disk space (incremental backup):
  - Automatic deduplication of parts of files (most modified files differ only partially).
  - All files will be compressed with archivator (compression level may be configured).
  - Incremental backup format doesn't require initial data snapshot.
- Security:
  - All files will be encrypted with AES256 + RSA4096.
  - Encryption doing before data send to storage host.
  - For backuping you don't need to keep private RSA key accessible to this program. It needs only for restoring.
  - Thus, even with the backup data, no one can get the source files from them. And also no one can fake a backup.
- You can specify different priorities for any files.
- For recover your backup you need only: access to storage host, your crypting keys and some backup options.
- You can backup to local directory or to remote sftp server.
- Requires on backuper host: perl and some perl libs.
- Requires on SFTP storage host: disk space only.

# Installing

You can install simple-backuper from CPAN (perl packages repository) or directly from github.

## From CPAN
`cpan install App::SimpleBackuper`

## From GitHub

- `git clone https://github.com/dmitry-novozhilov/simple-backuper.git`
- `cd simple-backuper`
- `make`
- `perl Makefile.pl`
- `sudo make install`

# Configuring

You need a configuration file. By default simple-backuper trying to read ~/.simple-backuper/config, but you can use other path.
In this case you need specify --cfg option on all simple-backuper run.  
This file is json with comments allowed. It can be like this:
```javascript
{
    "db":                   "~/.simple-backuper/db",        // This database file changes every new backup. ~/.simple-backuper/db - is a default value.
    
    "compression_level":    9,                              // LZMA algorythm supports levels 1 to 9
    
    "public_key":           "~/.simple-backuper/key.pub",   // This key using with "backup" command.
                                                            // For restore-db command you need to use private key of this public key.
                                                            
                                                            // Creating new pair of keys:
                                                            // Private (for restoring): openssl genrsa -out ~/.simple-backuper/key 4096
                                                            // Public (for backuping): openssl rsa -in ~/.simple-backuper/key -pubout > ~/.simple-backuper/key.pub
                                                            // Keep the private key as your most valuable asset. Copy it to a safe place.
                                                            // It is desirable not in the backup storage, otherwise it will make it possible to use the backup data for someone other than you.
    
    "storage":              "/mnt/backups",                 // Use "host:path" or "user@host:path" for remote SFTP storage.
                                                            // All transfered data already encrypted.
                                                            // If you choose SFTP, make sure that this SFTP server works without a password.
                                                            // This can be configured with ~/.ssh/ config and ssh key-based authorization.
    
    "space_limit":          "100G",                         // Maximum of disc space on storage.
                                                            // While this limit has been reached, simple-backuper deletes the oldest and lowest priority file.
                                                            // K means kilobytes, M - megabytes, G - gygabytes, T - terabytes.
    
    "files": {                                              // Files globs with it's priorityes.
        "~":                            5,
        "~/.gnupg":                     50,                 // The higher the priority, the less likely it is to delete these files.
        "~/.bash_history":              0,                  // Zero priority prohibits backup. Use it for exceptions.
        "~/.cache":                     0,
        "~/.local/share/Trash":         0,
        "~/.mozilla/firefox/*/Cache":   0,
        "~/.thumbnails":                0,
    }
}
```

# First (initial) backup

After configuring you need to try backuping to check for it works:
`simple-backuper backup --backup-name initial --verbose`  
The initial backup will take a long time. It takes me more than a day.  
The next backups will take much less time. Because usually only a small fraction of the files are changed.

# Scheduled backups

You can add to crontab next command:
```
0 0 * * * simple-backuper backup --backup-name `date -Idate`
```
It creates backup named as date every day.

# Logging

Simple backuper is so simple that it does not log itself. You can write logs from STDOUT & STDERR:
```
0 0 * * * simple-backuper backup --backup-name `date -Idate` 2>&1 >> simple-backuper.log
```

# Recovering

1. The first thing you need is a database file. If you have it, move to next step. Otherwise you can restore it from your backup storage:  
   `simple-backuper restore-db --storage YOUR_STORAGE --priv-key KEY`  
   YOUR_STORAGE - is your `storage` option from config. For example `my_ssh_backup_host:/path/to/backup/`.  
   KEY - is path to your private key!
2. Chose backup and files by exploring you storage by commands like `simple-backuper info`, `simple-backuper info /home`,..
3. Try to dry run of restoring files: `simple-backuper restore --path CHOSED_PATH --backup-name CHOSED_BACKUP --storage YOUR_STORAGE --destination TARGET_DIR`  
   CHOSED_PATH - is path in backup to restoring files.  
   CHOSED_BACKUP - is what version of your files must be restored.  
   YOUR_STORAGE - is your `storage` option from config. For example `my_ssh_backup_host:/path/to/backup/`.  
   TARGET_DIR - is dir for restored files.
4. If all ok, run restoring files with same command and `--write` argument!
