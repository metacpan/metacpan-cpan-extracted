-- Local override of the xmake-repo package recipe for libsdl3_mixer.
--
-- Deviations from packages/l/libsdl3_mixer/xmake.lua in xmake-repo:
--   * adds a Windows/vcpkg extsource plus an on_fetch gate that refuses it
--     unless the system core passes the core recipe's own version gate.
-- Keep this file in sync with the upstream recipe when bumping versions.
--
package("libsdl3_mixer")
    set_homepage("https://github.com/libsdl-org/SDL_mixer")
    set_description("An audio mixer that supports various file formats for Simple Directmedia Layer.")
    set_license("zlib")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::sdl3-mixer")
    elseif is_plat("linux") then
        add_extsources("pacman::sdl3_mixer", "apt::libsdl3-mixer-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sdl3_mixer")
    elseif is_plat("windows") then
        add_extsources("vcpkg::sdl3-mixer")
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
            print(string.format("libsdl3_mixer: vcpkg SDL3 core %s is older than 3.4.18, building from source",
                  core.version or "of unknown version"))
            return false
        end
        return self:find_package("vcpkg::sdl3-mixer", {system = true})
    end)

    add_urls("https://www.libsdl.org/projects/SDL_mixer/release/SDL3_mixer-$(version).zip",
             "https://github.com/libsdl-org/SDL_mixer/releases/download/release-$(version)/SDL3_mixer-$(version).zip", { alias = "archive" })
    add_urls("https://github.com/libsdl-org/SDL_mixer.git", {alias = "github", submodules = false})

    add_versions("archive:3.2.2", "09bb145c399231390b37024aeeeba82c0a105471184a231a5ce3993747ca9308")
    add_versions("archive:3.2.4", "bbf0173861d5ee66555605435d4f423261d228649cb03dcb6cf3d24063683625")

    add_versions("github:3.2.2", "release-3.2.2")
    add_versions("github:3.2.4", "release-3.2.4")

    -- Not on Windows: that platform installs from the official prebuilt package, so
    -- there is nothing to compile and cmake would only be pulled in to sit unused
    -- (a source-built dependency is also the slow, flaky part of the Windows/ARM leg,
    -- see issue #3).
    if not is_plat("windows") then
        add_deps("cmake")
    end

    on_load(function (package)
        package:add("deps", "libsdl3", { configs = { shared = package:config("shared") }})
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
            _install_windows_prebuilt(package, "SDL_mixer", "SDL3_mixer", "SDL3_mixer")
            return
        end

        local configs = {"-DSDLMIXER_TESTS=OFF", "-DSDLMIXER_EXAMPLES=OFF", "-DSDLMIXER_VENDORED=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("MIX_Version", {includes = "SDL3_mixer/SDL_mixer.h"}))
    end)
