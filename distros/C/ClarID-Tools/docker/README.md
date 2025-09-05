# Containerized Installation

### Method 3: Installing from Docker Hub

Pull the latest Docker image from [Docker Hub](https://hub.docker.com/r/manuelrueda/clarid-tools):

```bash
docker pull manuelrueda/clarid-tools:latest
docker image tag manuelrueda/clarid-tools:latest cnag/clarid-tools:latest
```

### Method 4: Installing from Dockerfile

Download the `Dockerfile` from [GitHub](https://github.com/CNAG-Biomedical-Informatics/clarid-tools/blob/main/Dockerfile):

```bash
wget https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/clarid-tools/main/docker/Dockerfile
```

Then build the container:

- **For Docker version 19.03 and above (supports buildx):**

  ```bash
  docker buildx build -t cnag/clarid-tools:latest .
  ```

- **For Docker versions older than 19.03 (no buildx support):**

  ```bash
  docker build -t cnag/clarid-tools:latest .
  ```

## Running and Interacting with the Container

To run the container:

```bash
docker run -tid -e USERNAME=root --name clarid-tools cnag/clarid-tools:latest
```

To connect to the container:

```bash
docker exec -ti clarid-tools bash
```

Or, to run directly from the host:

```bash
alias clarid-tools='docker exec -ti clarid-tools /usr/share/clarid-tools/bin/clarid-tools'
clarid-tools
```

## System requirements

- OS/ARCH supported: **linux/amd64** and **linux/arm64**.
- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Perl 5 (>= 5.36 core; installed by default in many Linux distributions). Check the version with `perl -v`
- 1GB of RAM
- \>= 1 core (ideally i7 or Xeon).
- At least 5GB HDD.

## Platform Compatibility
This distribution is written in pure Perl and is intended to run on any platform supported by Perl 5. It has been tested on Debian Linux and macOS. It is expected to work on Windows; please report any issues.

## Common errors: Symptoms and treatment

  * Dockerfile:

          * DNS errors

            - Error: Temporary failure resolving 'foo'

              Solution: https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error
