-- Local override of the xmake-repo package recipe for libsdl3_ttf.
--
-- Deviations from packages/l/libsdl3_ttf/xmake.lua in xmake-repo:
--   * freetype is forced to a SHARED build. A static libfreetype.a (xmake-built
--     or Homebrew) records its own deps (-lz, -lbz2, -lpng16, ...) only as
--     link-time requirements that neither librarydeps() nor a bare pkg-config
--     call surfaces on CI (no pkg-config on macOS runners; xmake's freetype2.pc
--     is not on PKG_CONFIG_PATH). A shared libfreetype carries those deps
--     itself, so linking a SHARED libsdl3_ttf needs no extra transitive
--     libraries on any platform. (The consumer installs this package with
--     kind => 'shared' for FFI via Affix.)
--   * on_install passes -DFREETYPE_INCLUDE_DIR_ft2build and
--     -DFREETYPE_INCLUDE_DIR_freetype2 instead of the single
--     -DFREETYPE_INCLUDE_DIRS that CMake's FindFreetype ignores.
--   * on Windows, "freetype" is added to the `packagedeps` of the cmake install
--     so xmake generates a FindFreetype module for CMake; hand-passed
--     -DFREETYPE_* cache vars otherwise get lost on some toolchains.
--   * freetype's `zlib` config is disabled (default is true). With it enabled the
--     freetype build on Windows only passes -DZLIB_* vars when its zlib dep
--     resolves non-system; when it doesn't, CMake's `find_package(ZLIB REQUIRED)`
--     fails the whole install. TTF itself needs no gzip'd font support, so disable
--     zlib to keep the freetype build self-contained everywhere.
--   * adds a Windows/vcpkg extsource plus an on_fetch gate that refuses it
--     unless the system core passes the core recipe's own version gate.
-- Keep this file in sync with the upstream recipe when bumping versions.
--
package("libsdl3_ttf")
    set_homepage("https://github.com/libsdl-org/SDL_ttf/")
    set_description("Simple DirectMedia Layer text rendering library")
    set_license("zlib")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::sdl3-ttf")
    elseif is_plat("linux") then
        add_extsources("pacman::sdl3_ttf", "apt::libsdl3-ttf-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sdl3_ttf")
    elseif is_plat("windows") then
        add_extsources("vcpkg::sdl3-ttf")
    end

    -- Windows/vcpkg only: never take vcpkg's extension while the system core
    -- fails the core recipe's own gate -- that is how the family ends up half
    -- system, half source-built, with two SDL3 ABIs in one link. This mirrors
    -- recipes/packages/l/libsdl3/xmake.lua on_fetch: vcpkg is the only system
    -- source on Windows, and the version floor is read from the same port
    -- revision format (keep "3.4.18" in sync with _MIN_SYSTEM_VERSION there).
    -- nil lets xmake's normal candidates run; false disables the system path
    -- outright -- @see core/package/package.lua _fetch_library.
    on_fetch(function (self, opt)
        if not opt.system or not self:is_plat("windows") then
            return
        end
        local semver = import("core.base.semver")
        local core = self:find_package("vcpkg::sdl3", {system = true})
        if not core then
            -- The core is going to come from source here; keep the extension
            -- with it rather than linking it against vcpkg's SDL3.
            return false
        end
        local comparable = (core.version or ""):gsub("%-%d+$", "")
        local satisfies = try {
            function () return semver.satisfies(comparable, ">=3.4.18") end
        }
        if not satisfies then
            print(string.format("libsdl3_ttf: vcpkg SDL3 core %s is older than 3.4.18, building from source",
                  core.version or "of unknown version"))
            return false
        end
        return self:find_package("vcpkg::sdl3-ttf", {system = true})
    end)

    add_urls("https://www.libsdl.org/projects/SDL_ttf/release/SDL3_ttf-$(version).zip",
             "https://github.com/libsdl-org/SDL_ttf/releases/download/release-$(version)/SDL3_ttf-$(version).zip", { alias = "archive" })
    add_urls("https://github.com/libsdl-org/SDL_ttf.git", {alias = "github", submodules = false})

    add_versions("archive:3.2.2", "d38c2078630e015777aafa1a1ce627df4323114a920c313274346c372ba0d19d")
    add_versions("archive:3.2.0", "ea75fa02ab328cccdff8bf36d2ec891e445e94fa301cd0ef34c662e24d30b704")

    add_versions("github:3.2.2", "release-3.2.2")
    add_versions("github:3.2.0", "release-3.2.0")

    -- Not on Windows: that platform installs from the official prebuilt package, so
    -- there is nothing to compile and cmake plus freetype would only be pulled in to
    -- sit unused. A forced-source freetype is exactly the slow, flaky dependency that
    -- broke the Windows/ARM leg (issue #3), so keep it off that platform too.
    if not is_plat("windows") then
        add_deps("cmake")
        -- Freetype must be shared AND built from source. A STATIC libfreetype.a
        -- (xmake-built or Homebrew) records its own deps (-lz, -lbz2, ...) only as
        -- link-time requirements that neither librarydeps() nor a bare pkg-config
        -- call surfaces on CI (no pkg-config on macOS runners; xmake's freetype2.pc
        -- is not on PKG_CONFIG_PATH). A shared libfreetype carries those deps
        -- itself, so linking a SHARED libsdl3_ttf needs no extra transitive
        -- libraries anywhere. `system = false` keeps xmake from satisfying freetype
        -- from a Homebrew/apt static lib despite the shared config (the fetch would
        -- otherwise prefer the system source and return its static archive).
        add_deps("freetype", {configs = {shared = true, zlib = false}, system = false})
    end

    add_configs("harfbuzz", {description = "Use harfbuzz to improve text shaping", default = false, type = "boolean"})
    add_configs("plutosvg", {description = "Use plutosvg for color emoji support", default = false, type = "boolean"})
    if is_plat("wasm") then
        add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = true})
    end

    if is_host("windows") then
        set_policy("platform.longpaths", true)
    end

    if on_check then
        on_check("android", function (package)
            if package:config("harfbuzz") then
                local ndk = package:toolchain("ndk"):config("ndkver")
                assert(ndk and tonumber(ndk) > 22, "package(libsdl3_ttf) dep(harfbuzz) require ndk version > 22")
            end
        end)
    end

    on_load(function (package)
        -- libsdl3_ttf 3.2.0 requires libsdl3 >= 3.2.6
        package:add("deps", "libsdl3 >=3.2.6", { configs = { shared = package:config("shared") }})
        if package:config("harfbuzz") then
            package:add("deps", "harfbuzz")
        end
        if package:config("plutosvg") then
            package:add("deps", "plutosvg", "plutovg")
        end
    end)

    on_install(function (package)

        -- See recipes/packages/l/libsdl3/xmake.lua for why Windows installs the official
        -- prebuilt package instead of compiling, and why the flavour follows the toolchain.
        -- The sub-arch comes from package:arch(), which Alien::SDL3's install_opts() pins
        -- to $Config{archname}, so the DLL handed back is the one the running Perl loads.
        -- Defined inside this callback on purpose: the package-definition scope only
        -- exposes a read-only `os` (no mkdir/cp/rm), see core/sandbox/sandbox.lua:239.
        local function _install_windows_prebuilt(package, github_repo, asset_prefix, linkname)
            local ver = package:version_str()
            local msvc = package:has_tool("cxx", "cl")
            local flavour = msvc and "VC" or "mingw"
            local url = string.format(
                "https://github.com/libsdl-org/%s/releases/download/release-%s/%s-devel-%s-%s.zip",
                github_repo, ver, asset_prefix, ver, flavour)

            local cachedir = package:cachedir()
            os.mkdir(cachedir)
            local zipfile = path.join(cachedir, string.format("%s-devel-%s-%s.zip", asset_prefix, ver, flavour))
            if not os.isfile(zipfile) then
                import("net.http.download")(url, zipfile)
            end
            local workdir = path.join(package:builddir(), "prebuilt")
            os.tryrm(workdir)
            os.mkdir(workdir)
            import("utils.archive.extract")(zipfile, workdir)

            -- Both flavours unpack to <prefix>-<version>/ at the archive root.
            local root = path.join(workdir, string.format("%s-%s", asset_prefix, ver))
            if not os.isdir(root) then
                raise("package(%s): %s unpacked without its %s/ root", package:name(), zipfile, asset_prefix .. "-" .. ver)
            end

            local lower = (package:arch() or ""):lower()
            local is_x64 = lower:find("x86_64", 1, true) or lower:find("amd64", 1, true) or lower:find("x64", 1, true)
            local is_arm = lower:find("arm64", 1, true) or lower:find("aarch64", 1, true)

            local incdir, libdir, bindir
            if msvc then
                local vcarch = is_arm and "arm64" or (is_x64 and "x64" or "x86")
                incdir = path.join(root, "include")
                libdir = path.join(root, "lib", vcarch)
                bindir = libdir
            else
                if is_arm then
                    raise("package(%s): SDL publishes no mingw arm64 prebuilt; use the MSVC toolchain instead",
                          package:name())
                elseif not is_x64 then
                    -- only i686/x86_64 mingw builds are published
                    raise("package(%s): no mingw prebuilt for arch %q; use the MSVC toolchain instead",
                          package:name(), package:arch() or "?")
                end
                local triple = "x86_64-w64-mingw32"
                incdir = path.join(root, triple, "include")
                libdir = path.join(root, triple, "lib")
                bindir = path.join(root, triple, "bin")
            end
            if not os.isdir(libdir) then
                raise("package(%s): prebuilt archive has no %s for arch %q", package:name(), libdir, package:arch() or "?")
            end

            local installdir = package:installdir()
            local incdst = path.join(installdir, "include")
            local libdst = path.join(installdir, "lib")
            local bindst = path.join(installdir, "bin")
            os.mkdir(incdst); os.mkdir(libdst); os.mkdir(bindst)

            -- Copy the *contents* of include/: a bare-dir cp would nest it one level deeper.
            os.cp(path.join(incdir, "*"), incdst)
            -- Import libraries for the linker.
            for _, pattern in ipairs({"*.lib", "*.dll.a", "*.a"}) do
                os.cp(path.join(libdir, pattern), libdst)
            end
            -- Runtime DLLs. Alien::Xrepo picks libpath -- the file FFI dlopens, which
            -- t/affix.t load_library()s -- from the first .dll it finds in the install, so
            -- the DLL must sit in lib/ as well as bin/, and bin/ is what xmake puts on the
            -- PATH it builds for on_test.
            os.cp(path.join(libdir, "*.dll"), libdst)
            os.cp(path.join(bindir, "*.dll"), bindst)
            os.cp(path.join(bindir, "*.dll"), libdst)
            -- The VC layout keeps codec DLLs in a side directory next to the main ones.
            local optional = path.join(libdir, "optional")
            if os.isdir(optional) then
                os.cp(path.join(optional, "*.dll"), libdst)
                os.cp(path.join(optional, "*.dll"), bindst)
            end

            -- CMake normally publishes these; a manual install has to declare them, or
            -- _generate_configs() raises "links not found!" for every consumer (including
            -- this package's own on_test). The dir entries must be relative: the manifest
            -- reader joins them onto the installdir itself
            -- (modules/package/manager/xmake/find_package.lua:81,144), so an absolute path
            -- would come back as installdir/C:/... and find_library would find nothing.
            package:add("includedirs", "include")
            package:add("linkdirs", "lib")
            package:add("bindirs", "bin")
            package:add("links", linkname)
        end

        if package:is_plat("windows") then
            _install_windows_prebuilt(package, "SDL_ttf", "SDL3_ttf", "SDL3_ttf")
            return
        end

        local configs = {"-DSDLTTF_SAMPLES=OFF", "-DSDLTTF_VENDORED=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DSDLTTF_HARFBUZZ=" .. (package:config("harfbuzz") and "ON" or "OFF"))
        table.insert(configs, "-DSDLTTF_PLUTOSVG=" .. (package:config("plutosvg") and "ON" or "OFF"))
        local freetype = package:dep("freetype")
        if freetype then
            local fetchinfo = freetype:fetch()
            if fetchinfo then
                local includedirs = table.wrap(fetchinfo.includedirs or fetchinfo.sysincludedirs)
                if #includedirs > 0 then
                    -- Freetype fix: see the header comment at the top of this file.
                    table.insert(configs, "-DFREETYPE_INCLUDE_DIR_ft2build=" .. table.concat(includedirs, ";"))
                    table.insert(configs, "-DFREETYPE_INCLUDE_DIR_freetype2=" .. table.concat(includedirs, ";"))
                end
                local libfiles = table.wrap(fetchinfo.libfiles)
                if #libfiles > 0 then
                    table.insert(configs, "-DFREETYPE_LIBRARY=" .. libfiles[1])
                end
            end
        end
        local install_deps = {"plutovg"}
        if package:is_plat("windows") then
            -- Let xmake generate the FindFreetype module for CMake; hand-passed
            -- -DFREETYPE_* cache vars are unreliable on some Windows toolchains.
            table.insert(install_deps, "freetype")
        end
        import("package.tools.cmake").install(package, configs, {packagedeps = install_deps})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("TTF_Init", {includes = "SDL3_ttf/SDL_ttf.h"}))
    end)
