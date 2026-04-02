# Containerized Installation

### Method 1: Installing from Docker Hub (fast)

Pull the latest Docker image from [Docker Hub](https://hub.docker.com/r/manuelrueda/clarid-tools):

```bash
docker pull manuelrueda/clarid-tools:latest
docker image tag manuelrueda/clarid-tools:latest cnag/clarid-tools:latest
```

### Method 2: Building from the repository Dockerfile

Download the `Dockerfile` from [GitHub](https://github.com/CNAG-Biomedical-Informatics/clarid-tools/blob/main/docker/Dockerfile):

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

The Docker image already includes the external QR dependencies used by `clarid-tools qrcode`, including `qrencode` and `zbarimg` (`zbar-tools`).

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
- 1GB of RAM
- \>= 1 core (ideally i7 or Xeon).
- At least 5GB HDD.

## Common errors: Symptoms and treatment

  * Dockerfile:

          * DNS errors

            - Error: Temporary failure resolving 'foo'

              Solution: https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error
