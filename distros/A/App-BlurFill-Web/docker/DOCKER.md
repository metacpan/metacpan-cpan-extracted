# Docker Usage

The `davorg/app-blurfill-web` image contains the Dancer2 web application. It is
built on the version-matched `davorg/app-blurfill` API/CLI image.

```bash
docker build \
  --build-arg APP_BLURFILL_VERSION=0.1.0 \
  -f docker/Dockerfile \
  -t davorg/app-blurfill-web:0.1.0 .

docker run --rm -p 8080:8080 davorg/app-blurfill-web:0.1.0
```

Open <http://localhost:8080/>. The application listens on port 8080 inside the
container. Set `APP_BLURFILL_VERSION` to select the versioned core image used as
the base; release builds should never use `latest` as their base.
