# Security Policy

## Reporting a Vulnerability

If you believe you have found a security issue in this project:

- Please **do not** open a public GitHub issue with sensitive details.
- Email: **sergio@serso.com**
- Include: a short description, reproduction steps (if possible), and impact.

I will respond as soon as practical and coordinate a fix/release if needed.

## Security Notes

- This tool is designed to avoid logging secrets (e.g., tokens).
- Recommended practice is to store credentials in environment variables (e.g., `EASYDNS_TOKEN`) and reference them from config.

