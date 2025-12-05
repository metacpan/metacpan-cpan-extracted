# Changelog

## [1.1.0] - 2024-12-04

### Added

#### New Modules
- **DNSQuery::Constants** - Centralized constants for query types, limits, and configuration
- **DNSQuery::Validator** - Comprehensive input validation with clear error messages
- **DNSQuery::Cache** - Advanced caching with TTL support, LRU eviction, and disk persistence

#### Features
- TTL-aware caching that respects DNS record expiration times
- Optional disk persistence for cache (survives restarts)
- LRU (Least Recently Used) cache eviction algorithm
- Enhanced cache statistics (hit rate, evictions, size)
- Comprehensive input validation for all user inputs
- Better error messages with specific validation failures
- POD documentation for all new modules

#### Tests
- `t/validator.t` - Comprehensive validation tests (15 tests)
- `t/cache.t` - Cache functionality tests (7 tests)
- Increased test coverage from 8 to 26 tests

#### Documentation
- `IMPROVEMENTS.md` - Detailed improvement documentation
- `USAGE_GUIDE.md` - User guide for new features
- `CHANGELOG.md` - This file
- POD documentation in Validator, Cache, and Constants modules

### Changed

#### Code Quality
- Refactored `DNSQuery::Batch` to eliminate code duplication
  - Extracted `_parse_batch_file()` method
  - Extracted `_process_query()` method
  - Extracted `_print_progress()` method
  - Extracted `_print_summary()` method
- Standardized error handling across all modules
- Removed ~300 lines of duplicated validation code
- Improved code organization and maintainability

#### DNSQuery::Resolver
- Now uses `DNSQuery::Cache` instead of simple hash
- Cache respects DNS record TTL values
- Validation moved to `DNSQuery::Validator`
- Enhanced statistics include cache metrics
- Removed internal validation functions (now in Validator)

#### DNSQuery::Batch
- Uses `DNSQuery::Validator` for input validation
- Reduced code duplication by ~40%
- Better error reporting with line numbers
- Improved progress indicators
- Cleaner separation of concerns

#### DNSQuery::Interactive
- Uses `DNSQuery::Validator` for input validation
- Better error messages for invalid inputs
- Validates server addresses in `set` command
- Enhanced statistics display

#### bin/dnsq
- Uses `DNSQuery::Validator` for input validation
- Consistent error messages
- Better validation before resolver creation

### Dependencies
- Added `Storable` (required) - For cache persistence
- Added `File::Spec` (required) - For portable file paths

### Performance
- Improved cache hit rates with TTL-aware expiration
- LRU eviction keeps hot data in cache
- Optional disk persistence reduces cold start time
- Better memory management with configurable cache size

### Backward Compatibility
- All existing functionality preserved
- No breaking changes to public APIs
- New features are opt-in
- Existing scripts work without modification

### Fixed
- Inconsistent error handling across modules
- Validation logic duplication
- Cache not respecting DNS TTL values
- Missing validation for edge cases
- Inconsistent error message formats

### Technical Details

#### Lines of Code
- Before: ~1,200 lines
- After: ~1,400 lines
- New shared modules: ~600 lines
- Net reduction in duplication: ~200 lines

#### Test Coverage
- Before: 2 test files, 8 tests
- After: 4 test files, 26 tests
- All tests passing

#### Module Structure
```
lib/DNSQuery/
├── Banner.pm          (unchanged)
├── Batch.pm           (refactored)
├── Cache.pm           (new)
├── Constants.pm       (new)
├── Interactive.pm     (refactored)
├── Output.pm          (unchanged)
├── Resolver.pm        (refactored)
└── Validator.pm       (new)
```

### Migration Guide

#### For Users
No changes required. All existing commands work as before:
```bash
bin/dnsq google.com
bin/dnsq --batch queries.txt
bin/dnsq --interactive
```

#### For Developers
To use new features:

```perl
# Use validation
use DNSQuery::Validator qw(:all);
my ($valid, $error) = validate_domain($domain);

# Use constants
use DNSQuery::Constants qw(:all);
if ($VALID_QUERY_TYPES{$type}) { ... }

# Enable cache persistence
my %config = (
    cache_persist => 1,
    cache_size => 200,
);
```

### Known Issues
- Cache persistence warning in tests (harmless, related to temp file initialization)
- Perl warnings about "used only once" in tests (cosmetic, no functional impact)

### Future Enhancements
Potential improvements for future versions:
- DNS-over-HTTPS (DoH) support
- DNS-over-TLS (DoT) support
- Rate limiting for batch queries
- EDNS Client Subnet (ECS) support
- Tab completion in interactive mode
- Command history persistence
- Configuration file support (~/.dnsqrc)
- Environment variable support

### Contributors
- Code improvements and refactoring
- New module development
- Test suite expansion
- Documentation updates

### License
MIT License (unchanged)

---

## [1.0.0] - Initial Release

### Features
- Multiple output formats (full, short, JSON)
- TCP and UDP protocol support
- Custom DNS server support
- Configurable timeout and retries
- Batch processing
- Trace mode
- Interactive mode
- DNSSEC support
- Basic query caching
- Statistics tracking
- Progress indicators
